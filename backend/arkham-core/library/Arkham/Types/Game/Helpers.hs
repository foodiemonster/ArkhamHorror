{-# OPTIONS_GHC -fno-warn-orphans #-}
module Arkham.Types.Game.Helpers where

import Arkham.Prelude

import Arkham.EncounterCard (allEncounterCards)
import Arkham.Types.Ability
import Arkham.Types.Action (Action)
import qualified Arkham.Types.Action as Action
import Arkham.Types.CampaignLogKey
import Arkham.Types.Card
import Arkham.Types.Card.Cost
import Arkham.Types.Card.Id
import Arkham.Types.ClassSymbol
import Arkham.Types.Classes
import Arkham.Types.Cost
import Arkham.Types.Effect.Window
import Arkham.Types.EffectMetadata
import Arkham.Types.GameValue
import Arkham.Types.Id
import Arkham.Types.Keyword
import qualified Arkham.Types.Keyword as Keyword
import qualified Arkham.Types.Label as Location
import Arkham.Types.Matcher
import Arkham.Types.Message
import Arkham.Types.Modifier
import Arkham.Types.Name
import Arkham.Types.PlayRestriction
import Arkham.Types.Query
import Arkham.Types.SkillType
import Arkham.Types.Source
import Arkham.Types.Target
import Arkham.Types.Token
import Arkham.Types.Trait (Trait, toTraits)
import Arkham.Types.Window
import Arkham.Types.WindowMatcher (WindowMatcher)
import qualified Arkham.Types.WindowMatcher as Matcher
import Control.Monad.Extra (allM, anyM)
import Data.UUID (nil)

checkWindows
  :: (MonadReader env m, HasSet InvestigatorId env ())
  => [Window]
  -> m [Message]
checkWindows windows = do
  iids <- getInvestigatorIds
  pure $ [ CheckWindow iid windows | iid <- iids ]

cancelToken :: (HasQueue env, MonadIO m, MonadReader env m) => Token -> m ()
cancelToken token = withQueue $ \queue ->
  ( filter
    (\case
      When (RevealToken _ _ token') | token == token' -> False
      RevealToken _ _ token' | token == token' -> False
      After (RevealToken _ _ token') | token == token' -> False
      RequestedTokens _ _ [token'] | token == token' -> False
      RequestedTokens{} -> error "not setup for multiple tokens"
      _ -> True
    )
    queue
  , ()
  )

replaceToken :: (HasQueue env, MonadIO m, MonadReader env m) => Token -> m ()
replaceToken token = withQueue $ \queue ->
  ( map
    (\case
      When (RevealToken s i _) -> When (RevealToken s i token)
      RevealToken s i _ -> RevealToken s i token
      After (RevealToken s i _) -> After (RevealToken s i token)
      RequestedTokens source' miid [_] -> RequestedTokens source' miid [token]
      RequestedTokens{} -> error "not setup for multiple tokens"
      m -> m
    )
    queue
  , ()
  )

withBaseActions
  :: (MonadIO m, HasActions env a, MonadReader env m)
  => InvestigatorId
  -> Window
  -> a
  -> m [Message]
  -> m [Message]
withBaseActions iid window a f = (<>) <$> getActions iid window a <*> f

getCanPerformAbility
  :: (MonadReader env m, MonadIO m, CanCheckPlayable env)
  => InvestigatorId
  -> Window
  -> Ability
  -> m Bool
getCanPerformAbility iid window Ability {..} =
  (&&) <$> meetsAbilityRestrictions <*> meetsActionRestrictions
 where
  meetsAbilityRestrictions = case abilityRestrictions of
    Nothing -> pure True
    Just restriction ->
      getCanPerformAbilityRestriction iid [window] restriction
  meetsActionRestrictions = case abilityType of
    ActionAbility (Just action) _ -> case action of
      Action.Fight -> hasFightActions iid window
      Action.Evade -> hasEvadeActions iid window
      Action.Investigate -> hasInvestigateActions iid window
      -- The below actions may not be handled correctly yet
      Action.Ability -> pure True
      Action.Draw -> pure True
      Action.Engage -> pure True
      Action.Move -> pure True
      Action.Parley -> pure True
      Action.Play -> pure True
      Action.Resign -> pure True
      Action.Resource -> pure True
    ActionAbility Nothing _ -> pure True
    FastAbility _ -> pure True
    ReactionAbility _ -> pure True
    ForcedAbility -> pure True

getCanPerformAbilityRestriction
  :: (MonadReader env m, CanCheckFast env, CanCheckPlayable env, MonadIO m)
  => InvestigatorId
  -> [Window]
  -> PlayRestriction
  -> m Bool
getCanPerformAbilityRestriction iid windows restrictions = do
  lid' <- getId @LocationId iid
  passesRestriction iid lid' windows restrictions

getCanAffordAbility
  :: ( MonadReader env m
     , HasModifiersFor env ()
     , HasCostPayment env
     , HasSet Trait env Source
     , HasList UsedAbility env ()
     )
  => InvestigatorId
  -> Ability
  -> m Bool
getCanAffordAbility iid ability =
  (&&) <$> getCanAffordUse iid ability <*> getCanAffordAbilityCost iid ability

getCanAffordAbilityCost
  :: ( MonadReader env m
     , HasModifiersFor env ()
     , HasCostPayment env
     , HasSet Trait env Source
     )
  => InvestigatorId
  -> Ability
  -> m Bool
getCanAffordAbilityCost iid Ability {..} = case abilityType of
  ActionAbility mAction cost -> getCanAffordCost iid abilitySource mAction cost
  ReactionAbility cost -> getCanAffordCost iid abilitySource Nothing cost
  FastAbility cost -> getCanAffordCost iid abilitySource Nothing cost
  ForcedAbility -> pure True

getCanAffordUse
  :: (MonadReader env m, HasCostPayment env, HasList UsedAbility env ())
  => InvestigatorId
  -> Ability
  -> m Bool
getCanAffordUse iid ability = case abilityLimit ability of
  NoLimit -> case abilityType ability of
    ReactionAbility _ ->
      notElem (iid, ability) . map unUsedAbility <$> getList ()
    ForcedAbility -> notElem (iid, ability) . map unUsedAbility <$> getList ()
    ActionAbility _ _ -> pure True
    FastAbility _ -> pure True
  PlayerLimit (PerSearch (Just _)) n ->
    (< n)
      . count ((== abilityLimit ability) . abilityLimit . snd . unUsedAbility)
      <$> getList ()
  PlayerLimit _ n ->
    (< n) . count (== (iid, ability)) . map unUsedAbility <$> getList ()
  PerInvestigatorLimit _ _ n -> do
    usedAbilities <- map unUsedAbility <$> getList ()
    let
      matchingAbilities = filter (== (iid, ability)) usedAbilities
      matchingPerInvestigatorCount =
        count ((== abilityLimit ability) . abilityLimit . snd) matchingAbilities
    pure $ matchingPerInvestigatorCount < n
  GroupLimit _ n ->
    (< n) . count (== ability) . map (snd . unUsedAbility) <$> getList ()

applyActionCostModifier :: Maybe Action -> ModifierType -> Int -> Int
applyActionCostModifier (Just action) (ActionCostOf (IsAction action') m) n
  | action == action' = n + m
applyActionCostModifier _ (ActionCostModifier m) n = n + m
applyActionCostModifier _ _ n = n

getCanAffordCost
  :: ( MonadReader env m
     , HasModifiersFor env ()
     , HasCostPayment env
     , HasSet Trait env Source
     )
  => InvestigatorId
  -> Source
  -> Maybe Action
  -> Cost
  -> m Bool
getCanAffordCost iid source mAction = \case
  Free -> pure True
  UpTo{} -> pure True
  AdditionalActionsCost{} -> pure True
  Costs xs -> and <$> traverse (getCanAffordCost iid source mAction) xs
  ExhaustCost target -> case target of
    AssetTarget aid -> do
      readyAssetIds <- selectList AssetReady
      pure $ aid `elem` readyAssetIds
    _ -> error "Not handled"
  ExhaustAssetCost matcher -> notNull <$> select (matcher <> AssetReady)
  UseCost aid _uType n -> do
    uses <- unUsesCount <$> getCount aid
    pure $ uses >= n
  ActionCost n -> do
    modifiers <- getModifiers source (InvestigatorTarget iid)
    if ActionsAreFree `elem` modifiers
      then pure True
      else do
        let
          modifiedActionCost =
            foldr (applyActionCostModifier mAction) n modifiers
        traits <- getSetList @Trait source
        actionCount <- unActionRemainingCount
          <$> getCount (mAction, traits, iid)
        pure $ actionCount >= modifiedActionCost
  ClueCost n -> do
    spendableClues <- unSpendableClueCount <$> getCount iid
    pure $ spendableClues >= n
  PlaceClueOnLocationCost n -> do
    spendableClues <- unSpendableClueCount <$> getCount iid
    pure $ spendableClues >= n
  GroupClueCost n Nothing -> do
    totalSpendableClues <- unSpendableClueCount <$> getCount ()
    cost <- getPlayerCountValue n
    pure $ totalSpendableClues >= cost
  GroupClueCost n (Just locationMatcher) -> do
    mLocationId <- getId @(Maybe LocationId) locationMatcher
    cost <- getPlayerCountValue n
    case mLocationId of
      Just lid -> do
        iids <- getSetList @InvestigatorId lid
        totalSpendableClues <- sum
          <$> for iids ((unSpendableClueCount <$>) . getCount)
        pure $ totalSpendableClues >= cost
      Nothing -> pure False
  ResourceCost n -> do
    resources <- unResourceCount <$> getCount iid
    pure $ resources >= n
  DiscardCost _ -> pure True -- TODO: Make better
  DiscardCardCost _ -> pure True -- TODO: Make better
  ExileCost _ -> pure True -- TODO: Make better
  RemoveCost _ -> pure True -- TODO: Make better
  HorrorCost{} -> pure True -- TODO: Make better
  DamageCost{} -> pure True -- TODO: Make better
  DoomCost{} -> pure True -- TODO: Make better
  SkillIconCost n skillTypes -> do
    handCards <- mapMaybe (preview _PlayerCard) <$> getHandOf iid
    let
      total = sum $ map
        (count (`member` insertSet SkillWild skillTypes) . cdSkills . toCardDef)
        handCards
    pure $ total >= n
  HandDiscardCost n mCardType traits skillTypes -> do
    cards <- mapMaybe (preview _PlayerCard) <$> getHandOf iid
    let
      cardTypeFilter = case mCardType of
        Nothing -> const True
        Just cardType' -> (== cardType') . cdCardType . toCardDef
      traitFilter = if null traits
        then const True
        else notNull . intersect traits . toTraits
      skillTypeFilter = if null skillTypes
        then const True
        else
          not
          . null
          . intersect (insertSet SkillWild skillTypes)
          . setFromList
          . cdSkills
          . toCardDef
    pure
      $ length
          (filter
            (and . sequence [traitFilter, cardTypeFilter, skillTypeFilter])
            cards
          )
      >= n

isForcedAction :: Message -> Bool
isForcedAction = \case
  Force _ -> True
  UseAbility _ ability -> abilityType ability == ForcedAbility
  _ -> False

instance
  ( HasCostPayment env
  , HasSet Trait env Source
  , HasList UsedAbility env ()
  , CanCheckPlayable env
  )
  => HasActions env () where
  getActions iid window _ = do
    actions' <- concat <$> traverse
      (getActions iid window)
      ([minBound .. maxBound] :: [ActionType])
    actions'' <- for actions' $ \case
      UseAbility iid' ability -> do
        modifiers' <- getModifiers
          (InvestigatorSource iid)
          (sourceToTarget $ abilitySource ability)
        pure $ UseAbility iid' (applyAbilityModifiers ability modifiers')
      other -> pure other -- TODO: dynamic abilities
    let forcedActions = nub $ filter isForcedAction actions''
    forcedActions' <- filterM
      (\case
        UseAbility iid' ability -> getCanAffordAbility iid' ability
        _ -> pure True
      )
      forcedActions
    if null forcedActions'
      then do
        let
          canAffordAction = \case
            UseAbility _ ability -> getCanAffordAbility iid ability
            MoveAction _ lid cost _ ->
              getCanAffordCost iid (LocationSource lid) (Just Action.Move) cost
            _ -> pure True
          canPerformAction = \case
            UseAbility _ ability -> getCanPerformAbility iid window ability
            _ -> pure True
        filterM
          (\action ->
            liftM2 (&&) (canPerformAction action) (canAffordAction action)
          )
          actions''
      else pure forcedActions'

enemyAtInvestigatorLocation
  :: ( MonadReader env m
     , HasId CardCode env EnemyId
     , HasId LocationId env InvestigatorId
     , HasSet EnemyId env LocationId
     )
  => CardCode
  -> InvestigatorId
  -> m Bool
enemyAtInvestigatorLocation cardCode iid = do
  lid <- getId @LocationId iid
  enemyIds <- getSetList @EnemyId lid
  elem cardCode <$> for enemyIds (getId @CardCode)

getHasRecord :: (HasRecord env, MonadReader env m) => CampaignLogKey -> m Bool
getHasRecord = hasRecord

getRecordCount :: (HasRecord env, MonadReader env m) => CampaignLogKey -> m Int
getRecordCount = hasRecordCount

getRecordSet
  :: (HasRecord env, MonadReader env m) => CampaignLogKey -> m [CardCode]
getRecordSet = hasRecordSet

getIsUnused'
  :: (HasList UsedAbility env (), MonadReader env m)
  => InvestigatorId
  -> Ability
  -> m Bool
getIsUnused' iid ability = notElem ability' . map unUsedAbility <$> getList ()
  where ability' = (iid, ability)

getGroupIsUnused
  :: (MonadReader env m, HasList UsedAbility env ()) => Ability -> m Bool
getGroupIsUnused ability =
  notElem ability . map (snd . unUsedAbility) <$> getList ()

getInvestigatorModifiers
  :: (MonadReader env m, HasModifiersFor env ())
  => InvestigatorId
  -> Source
  -> m [ModifierType]
getInvestigatorModifiers iid source =
  getModifiers source (InvestigatorTarget iid)

getXp
  :: ( HasCount XPCount env ()
     , HasModifiersFor env ()
     , HasSet InvestigatorId env ()
     , MonadReader env m
     )
  => m [(InvestigatorId, Int)]
getXp = do
  investigatorIds <- getInvestigatorIds
  for
    investigatorIds
    \iid -> do
      modifiers' <- getModifiers
        (InvestigatorSource iid)
        (InvestigatorTarget iid)
      amount <- unXPCount <$> getCount ()
      pure (iid, foldl' applyModifier amount modifiers')
 where
  applyModifier n (XPModifier m) = max 0 (n + m)
  applyModifier n _ = n

getLeadInvestigatorId
  :: (HasId LeadInvestigatorId env (), MonadReader env m) => m InvestigatorId
getLeadInvestigatorId = unLeadInvestigatorId <$> getId ()

getInvestigatorIds
  :: (HasSet InvestigatorId env (), MonadReader env m) => m [InvestigatorId]
getInvestigatorIds = getSetList ()

getPlayerCount :: (HasCount PlayerCount env (), MonadReader env m) => m Int
getPlayerCount = unPlayerCount <$> getCount ()

getPlayerCountValue
  :: (HasCount PlayerCount env (), MonadReader env m) => GameValue Int -> m Int
getPlayerCountValue gameValue = fromGameValue gameValue <$> getPlayerCount

getLocationSet
  :: (HasSet LocationId env (), MonadReader env m) => m (HashSet LocationId)
getLocationSet = getSet ()

getSpendableClueCount
  :: (MonadReader env m, HasCount SpendableClueCount env InvestigatorId)
  => [InvestigatorId]
  -> m Int
getSpendableClueCount investigatorIds =
  sum <$> for investigatorIds ((unSpendableClueCount <$>) . getCount)

-- TODO: canFight _ a@Attrs {..} = canDo Action.Fight a
getCanFight
  :: ( MonadReader env m
     , HasCostPayment env
     , HasSet InvestigatorId env EnemyId
     , HasSet Keyword env EnemyId
     , HasSet Trait env Source
     , HasId LocationId env InvestigatorId
     , HasId LocationId env EnemyId
     , HasModifiersFor env ()
     )
  => EnemyId
  -> InvestigatorId
  -> m Bool
getCanFight eid iid = do
  locationId <- getId @LocationId iid
  enemyModifiers <- getModifiers (InvestigatorSource iid) (EnemyTarget eid)
  sameLocation <- (== locationId) <$> getId @LocationId eid
  keywords <- getSet eid
  canAffordActions <- getCanAffordCost
    iid
    (EnemySource eid)
    (Just Action.Fight)
    (ActionCost 1)
  engagedInvestigators <- getSet eid
  pure
    $ canAffordActions
    && (Keyword.Aloof `notMember` keywords || iid `member` engagedInvestigators)
    && (sameLocation || CanBeFoughtAsIfAtYourLocation `elem` enemyModifiers)

getCanEngage
  :: ( MonadReader env m
     , HasCostPayment env
     , HasSet InvestigatorId env EnemyId
     , HasSet Trait env Source
     , HasId LocationId env InvestigatorId
     , HasId LocationId env EnemyId
     , HasModifiersFor env ()
     )
  => EnemyId
  -> InvestigatorId
  -> m Bool
getCanEngage eid iid = do
  locationId <- getId @LocationId iid
  sameLocation <- (== locationId) <$> getId @LocationId eid
  notEngaged <- notElem iid <$> getSet eid
  canAffordActions <- getCanAffordCost
    iid
    (EnemySource eid)
    (Just Action.Engage)
    (ActionCost 1)
  pure $ notEngaged && canAffordActions && sameLocation

getCanEvade
  :: ( MonadReader env m
     , HasCostPayment env
     , HasSet InvestigatorId env EnemyId
     , HasSet Trait env Source
     , HasModifiersFor env ()
     )
  => EnemyId
  -> InvestigatorId
  -> m Bool
getCanEvade eid iid = do
  engaged <- elem iid <$> getSet eid
  enemyModifiers <- getModifiers (InvestigatorSource iid) (EnemyTarget eid)
  canAffordActions <- getCanAffordCost
    iid
    (EnemySource eid)
    (Just Action.Evade)
    (ActionCost 1)
  pure $ engaged && canAffordActions && CannotBeEvaded `notElem` enemyModifiers

getCanMoveTo
  :: ( MonadReader env m
     , HasCostPayment env
     , HasSet AccessibleLocationId env LocationId
     , HasSet Trait env Source
     , HasId LocationId env InvestigatorId
     , HasModifiersFor env ()
     , HasCallStack
     )
  => LocationId
  -> InvestigatorId
  -> m Bool
getCanMoveTo lid iid = do
  locationId <- getId @LocationId iid
  modifiers' <- getModifiers (LocationSource lid) (InvestigatorTarget iid)
  locationModifiers' <- getModifiers
    (InvestigatorSource iid)
    (LocationTarget lid)
  accessibleLocations <- map unAccessibleLocationId <$> getSetList locationId
  canAffordActions <- getCanAffordCost
    iid
    (LocationSource lid)
    (Just Action.Move)
    (ActionCost 1)
  pure
    $ lid
    `elem` accessibleLocations
    && canAffordActions
    && lid
    /= locationId
    && CannotMove
    `notElem` modifiers'
    && Blocked
    `notElem` locationModifiers'

getCanInvestigate
  :: ( MonadReader env m
     , HasCostPayment env
     , HasId LocationId env InvestigatorId
     , HasSet Trait env Source
     , HasModifiersFor env ()
     )
  => LocationId
  -> InvestigatorId
  -> m Bool
getCanInvestigate lid iid = do
  locationId <- getId @LocationId iid
  canAffordActions <- getCanAffordCost
    iid
    (LocationSource lid)
    (Just Action.Investigate)
    (ActionCost 1)

  pure $ lid == locationId && canAffordActions

getResourceCount
  :: (MonadReader env m, HasCount ResourceCount env InvestigatorId)
  => InvestigatorId
  -> m Int
getResourceCount iid = unResourceCount <$> getCount iid

getDiscardOf
  :: (MonadReader env m, HasList DiscardedPlayerCard env InvestigatorId)
  => InvestigatorId
  -> m [PlayerCard]
getDiscardOf iid = map unDiscardedPlayerCard <$> getList iid

getHandOf
  :: (MonadReader env m, HasList HandCard env InvestigatorId)
  => InvestigatorId
  -> m [Card]
getHandOf iid = map unHandCard <$> getList iid

getInPlayOf
  :: (MonadReader env m, HasList InPlayCard env InvestigatorId)
  => InvestigatorId
  -> m [Card]
getInPlayOf iid = map unInPlayCard <$> getList iid

getCardCount
  :: (MonadReader env m, HasCount CardCount env InvestigatorId)
  => InvestigatorId
  -> m Int
getCardCount iid = unCardCount <$> getCount iid

toModifier :: SourceEntity a => a -> ModifierType -> Modifier
toModifier = Modifier . toSource

toModifiers :: SourceEntity a => a -> [ModifierType] -> [Modifier]
toModifiers = map . toModifier

targetToSource :: Target -> Source
targetToSource = \case
  InvestigatorTarget iid -> InvestigatorSource iid
  AssetTarget aid -> AssetSource aid
  EnemyTarget eid -> EnemySource eid
  ScenarioTarget sid -> ScenarioSource sid
  EffectTarget eid -> EffectSource eid
  PhaseTarget _ -> error "no need"
  LocationTarget lid -> LocationSource lid
  (SetAsideLocationsTarget _) -> error "can not convert"
  SkillTestTarget -> error "can not convert"
  AfterSkillTestTarget -> AfterSkillTestSource
  TreacheryTarget tid -> TreacherySource tid
  EncounterDeckTarget -> error "can not covert"
  ScenarioDeckTarget -> error "can not covert"
  AgendaTarget aid -> AgendaSource aid
  ActTarget aid -> ActSource aid
  CardIdTarget _ -> error "can not convert"
  CardCodeTarget _ -> error "can not convert"
  SearchedCardTarget _ _ -> error "can not convert"
  EventTarget eid -> EventSource eid
  SkillTarget sid -> SkillSource sid
  SkillTestInitiatorTarget _ -> error "can not convert"
  TokenTarget tid -> TokenSource tid
  TokenFaceTarget _ -> error "Not convertable"
  TestTarget -> TestSource mempty
  ResourceTarget -> ResourceSource
  ActDeckTarget -> ActDeckSource
  AgendaDeckTarget -> AgendaDeckSource
  InvestigationTarget{} -> error "not converted"

sourceToTarget :: Source -> Target
sourceToTarget = \case
  AssetSource aid -> AssetTarget aid
  EnemySource eid -> EnemyTarget eid
  CardIdSource cid -> CardIdTarget cid
  ScenarioSource sid -> ScenarioTarget sid
  InvestigatorSource iid -> InvestigatorTarget iid
  CardCodeSource cid -> CardCodeTarget cid
  TokenSource t -> TokenTarget t
  TokenEffectSource _ -> error "not implemented"
  AgendaSource aid -> AgendaTarget aid
  LocationSource lid -> LocationTarget lid
  SkillTestSource{} -> SkillTestTarget
  AfterSkillTestSource -> AfterSkillTestTarget
  TreacherySource tid -> TreacheryTarget tid
  EventSource eid -> EventTarget eid
  SkillSource sid -> SkillTarget sid
  EmptyDeckSource -> error "not implemented"
  DeckSource -> error "not implemented"
  GameSource -> error "not implemented"
  ActSource aid -> ActTarget aid
  PlayerCardSource cid -> CardIdTarget cid
  EncounterCardSource _ -> error "not implemented"
  TestSource{} -> TestTarget
  ProxySource _ source -> sourceToTarget source
  EffectSource eid -> EffectTarget eid
  ResourceSource -> ResourceTarget
  AbilitySource{} -> error "not implemented"
  ActDeckSource -> ActDeckTarget
  AgendaDeckSource -> AgendaDeckTarget

addCampaignCardToDeckChoice
  :: InvestigatorId -> [InvestigatorId] -> CardDef -> Message
addCampaignCardToDeckChoice leadInvestigatorId investigatorIds cardDef =
  chooseOne
    leadInvestigatorId
    [ Label
      ("Add " <> display name <> " to a deck")
      [ chooseOne
          leadInvestigatorId
          [ TargetLabel
              (InvestigatorTarget iid)
              [AddCampaignCardToDeck iid cardDef]
          | iid <- investigatorIds
          ]
      ]
    , Label ("Do not add " <> display name <> " to any deck") []
    ]
  where name = cdName cardDef

skillTestModifier
  :: (SourceEntity source, TargetEntity target)
  => source
  -> target
  -> ModifierType
  -> Message
skillTestModifier source target modifier =
  skillTestModifiers source target [modifier]

skillTestModifiers
  :: (SourceEntity source, TargetEntity target)
  => source
  -> target
  -> [ModifierType]
  -> Message
skillTestModifiers source target modifiers = CreateWindowModifierEffect
  EffectSkillTestWindow
  (EffectModifiers $ toModifiers source modifiers)
  (toSource source)
  (toTarget target)

getJustLocationIdByName
  :: (MonadReader env m, HasId (Maybe LocationId) env LocationMatcher)
  => Name
  -> m LocationId
getJustLocationIdByName name =
  fromJustNote ("Missing " <> show name) <$> getLocationIdByName name

getLocationIdByName
  :: (MonadReader env m, HasId (Maybe LocationId) env LocationMatcher)
  => Name
  -> m (Maybe LocationId)
getLocationIdByName name = getId matcher
 where
  matcher = case (nameTitle name, nameSubtitle name) of
    (title, Just subtitle) -> LocationWithFullTitle title subtitle
    (title, Nothing) -> LocationWithTitle title

fightAction
  :: SourceEntity source => InvestigatorId -> source -> Int -> [Cost] -> Message
fightAction iid source n costs = UseAbility
  iid
  (mkAbility
    (toSource source)
    n
    (ActionAbility (Just Action.Fight) (Costs costs))
  )

hasFightActions
  :: forall env m
   . (MonadIO m, MonadReader env m, HasActions env ActionType)
  => InvestigatorId
  -> Window
  -> m Bool
hasFightActions i NonFast = do
  enemyActions <- getActions i NonFast EnemyActionType
  pure $ or [ True | FightEnemy{} <- enemyActions ]
hasFightActions _ _ = pure False

hasEvadeActions
  :: forall env m
   . (MonadIO m, MonadReader env m, HasActions env ActionType)
  => InvestigatorId
  -> Window
  -> m Bool
hasEvadeActions i NonFast = do
  enemyActions <- getActions i NonFast EnemyActionType
  pure $ or [ True | EvadeEnemy{} <- enemyActions ]
hasEvadeActions _ _ = pure False

hasInvestigateActions
  :: forall env m
   . (MonadIO m, MonadReader env m, HasActions env ActionType)
  => InvestigatorId
  -> Window
  -> m Bool
hasInvestigateActions i NonFast = do
  locationActions <- getActions i NonFast LocationActionType
  pure $ or [ True | Investigate{} <- locationActions ]
hasInvestigateActions _ _ = pure False

type CanCheckPlayable env
  = ( HasModifiersFor env ()
    , Query AssetMatcher env
    , CanCheckFast env
    , HasCount ActionTakenCount env InvestigatorId
    , HasSet InvestigatorId env LocationId
    , HasSet EnemyId env LocationId
    , HasSet EnemyId env EnemyMatcher
    , HasSet LocationId env LocationMatcher
    , HasSet Trait env EnemyId
    , HasCount ClueCount env LocationId
    , HasActions env ActionType
    , HasSet EnemyId env InvestigatorId
    , HasCount ResourceCount env InvestigatorId
    , HasCount DoomCount env AssetId
    , HasCount DoomCount env InvestigatorId
    , HasList DiscardedPlayerCard env InvestigatorId
    , HasSet InvestigatorId env InvestigatorMatcher
    , HasSet AssetId env AssetMatcher
    , HasSet InvestigatorId env ()
    )

getIsPlayable
  :: (MonadReader env m, MonadIO m, CanCheckPlayable env)
  => InvestigatorId
  -> [Window]
  -> Card
  -> m Bool
getIsPlayable _ _ (EncounterCard _) = pure False -- TODO: there might be some playable ones?
getIsPlayable iid windows c@(PlayerCard _) = do
  modifiers <- getModifiers (InvestigatorSource iid) (InvestigatorTarget iid)
  availableResources <- unResourceCount <$> getCount iid
  engagedEnemies <- getSet @EnemyId iid
  location <- getId @LocationId iid
  modifiedCardCost <- getModifiedCardCost iid c
  passesRestrictions <- maybe
    (pure True)
    (passesRestriction iid location windows)
    (cdPlayRestrictions pcDef)
  inFastWindow <- maybe
    (pure False)
    (cardInFastWindows iid c windows)
    (cdFastWindow pcDef)
  pure
    $ (cdCardType pcDef /= SkillType)
    && (modifiedCardCost <= availableResources)
    && none prevents modifiers
    && (isNothing (cdFastWindow pcDef) || inFastWindow)
    && (cdAction pcDef /= Just Action.Evade || notNull engagedEnemies)
    && passesRestrictions
 where
  pcDef = toCardDef c
  prevents (CanOnlyUseCardsInRole role) =
    cdClassSymbol pcDef `notElem` [Just Neutral, Just role, Nothing]
  prevents (CannotPlay typePairs) = any
    (\(cType, traits) ->
      cdCardType pcDef
        == cType
        && (null traits || notNull (intersection (toTraits pcDef) traits))
    )
    typePairs
  prevents _ = False

passesRestriction
  :: (MonadReader env m, CanCheckFast env, CanCheckPlayable env, MonadIO m)
  => InvestigatorId
  -> LocationId
  -> [Window]
  -> PlayRestriction
  -> m Bool
passesRestriction iid location windows = \case
  FirstAction -> do
    n <- unActionTakenCount <$> getCount iid
    pure $ n == 0
  OnLocation lid -> pure $ location == lid
  ReturnableCardInDiscard AnyPlayerDiscard traits -> do
    investigatorIds <-
      filterM
          (fmap (notElem CardsCannotLeaveYourDiscardPile)
          . getModifiers GameSource
          . InvestigatorTarget
          )
        =<< getInvestigatorIds
    discards <-
      concat
        <$> traverse
              (fmap (map unDiscardedPlayerCard) . getList)
              investigatorIds
    let
      filteredDiscards = case traits of
        [] -> discards
        traitsToMatch ->
          filter (any (`elem` traitsToMatch) . toTraits) discards
    pure $ notNull filteredDiscards
  CardInDiscard AnyPlayerDiscard traits -> do
    investigatorIds <- getInvestigatorIds
    discards <-
      concat
        <$> traverse
              (fmap (map unDiscardedPlayerCard) . getList)
              investigatorIds
    let
      filteredDiscards = case traits of
        [] -> discards
        traitsToMatch ->
          filter (any (`elem` traitsToMatch) . toTraits) discards
    pure $ notNull filteredDiscards
  ClueOnLocation -> liftA2
    (&&)
    (pure $ location /= LocationId (CardId nil))
    ((> 0) . unClueCount <$> getCount location)
  EnemyExists matcher -> notNull <$> getSet @EnemyId matcher
  NoEnemyExists matcher -> null <$> getSet @EnemyId matcher
  AssetExists matcher -> notNull <$> getSet @AssetId matcher
  InvestigatorExists matcher -> notNull <$> getSet @InvestigatorId matcher
  PlayRestrictions rs -> allM (passesRestriction iid location windows) rs
  AnyPlayRestriction rs -> anyM (passesRestriction iid location windows) rs
  LocationExists matcher -> notNull <$> getSet @LocationId matcher
  AnotherInvestigatorInSameLocation -> liftA2
    (&&)
    (pure $ location /= LocationId (CardId nil))
    (notNull <$> getSet @InvestigatorId location)
  InvestigatorIsAlone -> liftA2
    (&&)
    (pure $ location /= LocationId (CardId nil))
    (null <$> getSet @InvestigatorId location)
  OwnCardWithDoom -> do
    assetIds <- selectList (AssetOwnedBy You)
    investigatorDoomCount <- unDoomCount <$> getCount iid
    assetsWithDoomCount <- filterM
      (fmap ((> 0) . unDoomCount) . getCount)
      assetIds
    pure $ investigatorDoomCount > 0 || notNull assetsWithDoomCount
  ScenarioCardHasResignAbility -> do
    actions' <- concat . concat <$> sequence
      [ traverse
          (getActions iid window)
          ([minBound .. maxBound] :: [ActionType])
      | window <- windows
      ]
    pure $ flip
      any
      actions'
      \case
        UseAbility _ ability -> case abilityType ability of
          ActionAbility (Just Action.Resign) _ -> True
          _ -> False
        _ -> False

getModifiedCardCost
  :: (MonadReader env m, HasModifiersFor env ())
  => InvestigatorId
  -> Card
  -> m Int
getModifiedCardCost iid c@(PlayerCard _) = do
  modifiers <- getModifiers (InvestigatorSource iid) (InvestigatorTarget iid)
  pure $ foldr applyModifier startingCost modifiers
 where
  pcDef = toCardDef c
  startingCost = case cdCost pcDef of
    Just (StaticCost n) -> n
    Just DynamicCost -> 0
    Nothing -> 0
  applyModifier (ReduceCostOf cardMatcher m) n | cardMatch c cardMatcher =
    max 0 (n - m)
  applyModifier _ n = n
getModifiedCardCost iid c@(EncounterCard _) = do
  modifiers <- getModifiers (InvestigatorSource iid) (InvestigatorTarget iid)
  pure $ foldr
    applyModifier
    (error "we need so specify ecCost for this to work")
    modifiers
 where
  applyModifier (ReduceCostOf cardMatcher m) n | cardMatch c cardMatcher =
    max 0 (n - m)
  applyModifier _ n = n

type CanCheckFast env
  = ( HasSet Trait env EnemyId
    , HasCount DamageCount env InvestigatorId
    , HasSet AccessibleLocationId env LocationId
    , HasSet InvestigatorId env LocationId
    , HasSet RevealedLocationId env ()
    , HasSet InvestigatorId env EnemyId
    , HasSet EnemyId env LocationId
    , HasSet TreacheryId env LocationId
    , HasId LocationId env InvestigatorId
    , HasId LocationId env EnemyId
    , HasId CardCode env TreacheryId
    , HasId CardCode env EnemyId
    , HasSet Trait env LocationId
    , HasSet Keyword env EnemyId
    , HasSet FarthestLocationId env (InvestigatorId, LocationMatcher)
    , HasName env LocationId
    , HasName env EnemyId
    , HasCount PlayerCount env ()
    , Location.GetLabel env LocationId
    , HasTokenValue env ()
    )

cardInFastWindows
  :: (MonadReader env m, CanCheckFast env, MonadIO m)
  => InvestigatorId
  -> Card
  -> [Window]
  -> WindowMatcher
  -> m Bool
cardInFastWindows iid _ windows matcher = anyM
  (`windowMatches` matcher)
  windows
 where
  windowMatches window' = \case
    Matcher.PhaseBegins _whenMatcher phaseMatcher -> case window' of
      AnyPhaseBegins -> pure $ phaseMatcher == Matcher.AnyPhase
      PhaseBegins _ -> case phaseMatcher of
        Matcher.AnyPhase -> pure True
      _ -> pure False
    Matcher.AfterTurnBegins whoMatcher -> case window' of
      AfterTurnBegins who -> matchWho who whoMatcher
      _ -> pure False
    Matcher.WhenWouldHaveSkillTestResult whoMatcher _ skillTestResultMatcher ->
      case skillTestResultMatcher of
        Matcher.FailureResult _ -> case window' of
          WhenWouldFailSkillTest who -> matchWho who whoMatcher
          _ -> pure False
        Matcher.SuccessResult _ -> pure False -- no pass window exists yet, add below too if added
        Matcher.AnyResult -> case window' of
          WhenWouldFailSkillTest who -> matchWho who whoMatcher
          -- TODO: Add success window if it exists
          _ -> pure False
    Matcher.SkillTestResult whenMatcher whoMatcher skillMatcher skillTestResultMatcher
      -> case skillTestResultMatcher of
        Matcher.FailureResult gameValueMatcher -> case window' of
          AfterFailInvestigationSkillTest who n
            | whenMatcher
              == Matcher.After
              && skillMatcher
              == Matcher.WhileInvestigating
            -> liftA2
              (&&)
              (matchWho who whoMatcher)
              (gameValueMatches n gameValueMatcher)
          AfterFailSkillTest who n
            | whenMatcher
              == Matcher.After
              && skillMatcher
              == Matcher.AnySkillTest -> liftA2
              (&&)
              (matchWho who whoMatcher)
              (gameValueMatches n gameValueMatcher)
          _ -> pure False
        Matcher.SuccessResult gameValueMatcher
          | skillMatcher == Matcher.AnySkillTest -> case window' of
            AfterPassSkillTest _ _ who n | whenMatcher == Matcher.After ->
              liftA2
                (&&)
                (matchWho who whoMatcher)
                (gameValueMatches n gameValueMatcher)
            _ -> pure False
        Matcher.AnyResult -> case window' of
          AfterFailSkillTest who _ | whenMatcher == Matcher.After ->
            matchWho who whoMatcher
          AfterPassSkillTest _ _ who _ | whenMatcher == Matcher.After ->
            matchWho who whoMatcher
          _ -> pure False
        _ -> pure False
    Matcher.DuringTurn whoMatcher -> case window' of
      DuringTurn who -> matchWho who whoMatcher
      _ -> pure False
    Matcher.OrWindowMatcher matchers -> anyM (windowMatches window') matchers
    Matcher.WhenEnemySpawns whereMatcher enemyMatcher -> case window' of
      WhenEnemySpawns enemyId locationId -> liftA2
        (&&)
        (enemyMatches enemyId enemyMatcher)
        (locationMatches locationId whereMatcher)
      _ -> pure False
    Matcher.EnemyAttacks timingMatcher whoMatcher enemyMatcher ->
      case window' of
        WhenEnemyAttacks who enemyId | timingMatcher == Matcher.When -> liftA2
          (&&)
          (matchWho who whoMatcher)
          (enemyMatches enemyId enemyMatcher)
        _ -> pure False
    Matcher.EnemyEvaded timingMatcher whoMatcher enemyMatcher ->
      case window' of
        AfterEnemyEvaded who enemyId | timingMatcher == Matcher.After -> liftA2
          (&&)
          (enemyMatches enemyId enemyMatcher)
          (matchWho who whoMatcher)
        _ -> pure False
    Matcher.MythosStep mythosStepMatcher -> case window' of
      WhenAllDrawEncounterCard ->
        pure $ mythosStepMatcher == Matcher.WhenAllDrawEncounterCard
      _ -> pure False
    Matcher.RevealChaosToken whenMatcher whoMatcher tokenMatcher ->
      case window' of
        WhenRevealToken who token | whenMatcher == Matcher.When -> liftA2
          (&&)
          (matchWho who whoMatcher)
          (matchToken who token tokenMatcher)
        AfterRevealToken who token | whenMatcher == Matcher.After -> liftA2
          (&&)
          (matchWho who whoMatcher)
          (matchToken who token tokenMatcher)
        _ -> pure False
    Matcher.EnemyDefeated timingMatcher whoMatcher enemyMatcher ->
      case window' of
        AfterEnemyDefeated who enemyId | timingMatcher == Matcher.After ->
          liftA2
            (&&)
            (enemyMatches enemyId enemyMatcher)
            (matchWho who whoMatcher)
        _ -> pure False
    Matcher.FastPlayerWindow -> pure $ window' == FastPlayerWindow
    Matcher.DealtDamageOrHorror whoMatcher -> case whoMatcher of
      You -> case window' of
        WhenWouldTakeDamageOrHorror _ (InvestigatorTarget iid') _ _ ->
          pure $ iid == iid'
        _ -> pure False
      _ -> pure False
    Matcher.DrawCard whenMatcher whoMatcher cardMatcher -> case window' of
      WhenDrawCard who card | whenMatcher == Matcher.When ->
        liftA2 (&&) (matchWho who whoMatcher) (matchCard card cardMatcher)
      AfterDrawCard who card | whenMatcher == Matcher.After ->
        liftA2 (&&) (matchWho who whoMatcher) (matchCard card cardMatcher)
      _ -> pure False
  matchWho who = \case
    Anyone -> pure True
    You -> pure $ who == iid
    NotYou -> pure $ who /= iid
    InvestigatorAtYourLocation ->
      liftA2 (==) (getId @LocationId iid) (getId @LocationId who)
    InvestigatorWithDamage -> (> 0) . unDamageCount <$> getCount who
    InvestigatorWithId iid' -> pure $ who == iid'
    InvestigatorMatches is -> allM (matchWho who) is
  gameValueMatches n = \case
    Matcher.AnyValue -> pure True
    Matcher.LessThan gv -> (n <) <$> getPlayerCountValue gv
  enemyMatches enemyId = \case
    EnemyEngagedWithYou -> member iid <$> getSet enemyId
    EnemyWithId eid -> pure $ eid == enemyId
    NonWeaknessEnemy -> do
      cardCode <- getId @CardCode enemyId
      pure . isJust $ lookup cardCode allEncounterCards
    AnyEnemy -> pure True
    EnemyWithKeyword k -> member k <$> getSet enemyId
    EnemyWithTrait t -> member t <$> getSet enemyId
    EnemyWithoutTrait t -> notMember t <$> getSet enemyId
    EnemyAtYourLocation ->
      liftA2 (==) (getId @LocationId iid) (getId @LocationId enemyId)
    EnemyAtLocation lid -> (== lid) <$> getId @LocationId enemyId
    EnemyMatchAll es -> allM (enemyMatches enemyId) es
    EnemyWithTitle title -> (== title) . nameTitle <$> getName enemyId
    EnemyWithFullTitle title subtitle ->
      (== Name title (Just subtitle)) <$> getName enemyId
  locationMatches locationId = \case
    LocationWithLabel label ->
      (== label) . Location.unLabel <$> Location.getLabel locationId
    LocationWithTitle title -> (== title) . nameTitle <$> getName locationId
    LocationWithFullTitle title subtitle ->
      (== Name title (Just subtitle)) <$> getName locationId
    LocationWithId lid -> pure $ lid == locationId
    Anywhere -> pure True
    EmptyLocation -> liftA2
      (&&)
      (null <$> getSet @EnemyId locationId)
      (null <$> getSet @InvestigatorId locationId)
    LocationWithoutInvestigators -> null <$> getSet @InvestigatorId locationId
    LocationWithoutEnemies -> null <$> getSet @EnemyId locationId
    AccessibleLocation -> do
      yourLocationId <- getId @LocationId iid
      member (AccessibleLocationId locationId) <$> getSet yourLocationId
    RevealedLocation -> member (RevealedLocationId locationId) <$> getSet ()
    YourLocation -> do
      yourLocationId <- getId @LocationId iid
      pure $ locationId == yourLocationId
    NotYourLocation -> do
      yourLocationId <- getId @LocationId iid
      pure $ locationId /= yourLocationId
    FarthestLocationFromYou matcher' ->
      member (FarthestLocationId locationId) <$> getSet (iid, matcher')
    LocationWithTrait t -> member t <$> getSet locationId
    LocationMatchers ms -> allM (locationMatches locationId) ms
    LocationWithoutTreacheryWithCardCode cCode -> do
      treacheryIds <- getSetList @TreacheryId locationId
      cardCodes <- traverse (getId @CardCode) treacheryIds
      pure $ cCode `notElem` cardCodes
  matchCard c = \case
    Matcher.AnyCard -> pure True
    Matcher.NonWeakness -> pure . not . cdWeakness $ toCardDef c
    Matcher.WithCardType cType -> pure $ toCardType c == cType
    Matcher.CardMatchesAny ms -> anyM (matchCard c) ms
    Matcher.CardMatches ms -> allM (matchCard c) ms
    Matcher.CardWithoutKeyword kw ->
      pure $ kw `notElem` cdKeywords (toCardDef c)
  matchToken iid' t = \case
    Matcher.WithNegativeModifier -> do
      tv <- getTokenValue () iid' (tokenFace t)
      case tv of
        TokenValue _ (NegativeModifier _) -> pure True
        TokenValue _ (DoubleNegativeModifier _) -> pure True
        _ -> pure False

getModifiedTokenFaces
  :: (SourceEntity source, MonadReader env m, HasModifiersFor env ())
  => source
  -> [Token]
  -> m [TokenFace]
getModifiedTokenFaces source tokens = flip
  concatMapM
  tokens
  \token -> do
    modifiers' <- getModifiers (toSource source) (TokenTarget token)
    pure $ foldl' applyModifier [tokenFace token] modifiers'
 where
  applyModifier _ (TokenFaceModifier fs') = fs'
  applyModifier [f'] (ForcedTokenChange f fs) | f == f' = fs
  applyModifier fs _ = fs
