module Arkham.Types.Asset.Cards.ArchaicGlyphs
  ( archaicGlyphs
  , ArchaicGlyphs(..)
  ) where

import Arkham.Prelude

import Arkham.Asset.Cards qualified as Cards
import Arkham.Types.Ability
import Arkham.Types.Asset.Attrs
import Arkham.Types.CampaignLogKey
import Arkham.Types.Cost
import Arkham.Types.Criteria
import Arkham.Types.SkillType

newtype ArchaicGlyphs = ArchaicGlyphs AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor env)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

archaicGlyphs :: AssetCard ArchaicGlyphs
archaicGlyphs = asset ArchaicGlyphs Cards.archaicGlyphs

instance HasAbilities ArchaicGlyphs where
  getAbilities (ArchaicGlyphs attrs) =
    [ restrictedAbility attrs 1 OwnsThis
        $ ActionAbility Nothing
        $ SkillIconCost 1
        $ singleton SkillIntellect
    ]

instance AssetRunner env => RunMessage env ArchaicGlyphs where
  runMessage msg a@(ArchaicGlyphs attrs) = case msg of
    UseCardAbility _ source _ 1 _ | isSource attrs source ->
      a <$ push (AddUses (toTarget attrs) Secret 1)
    AddUses target Secret _ | isTarget attrs target -> do
      let ownerId = fromJustNote "must be owned" $ assetInvestigator attrs
      attrs' <- runMessage msg attrs
      ArchaicGlyphs attrs' <$ when
        (useCount (assetUses attrs') >= 3)
        (pushAll
          [ Discard (toTarget attrs)
          , TakeResources ownerId 5 False
          , Record YouHaveTranslatedTheGlyphs
          ]
        )
    _ -> ArchaicGlyphs <$> runMessage msg attrs
