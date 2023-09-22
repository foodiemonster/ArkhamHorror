module Arkham.Asset.Cards.JordanPerry (
  jordanPerry,
  JordanPerry (..),
) where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Runner
import Arkham.Card
import Arkham.Matcher
import Arkham.Story.Cards qualified as Story

newtype JordanPerry = JordanPerry AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

jordanPerry :: AssetCard JordanPerry
jordanPerry = asset JordanPerry Cards.jordanPerry

instance HasAbilities JordanPerry where
  getAbilities (JordanPerry a) =
    [ restrictedAbility
        a
        1
        (OnSameLocation <> InvestigatorExists (You <> InvestigatorWithResources (atLeast 10)))
        actionAbility
    , mkAbility a 2 $ ForcedAbility $ LastClueRemovedFromAsset #when $ AssetWithId (toId a)
    ]

instance RunMessage JordanPerry where
  runMessage msg a@(JordanPerry attrs) = case msg of
    UseThisAbility iid (isSource attrs -> True) 1 -> do
      push $ beginSkillTest iid (toAbilitySource attrs 1) attrs #intellect 2
      pure a
    PassedThisSkillTest iid (isSource attrs -> True) -> do
      let source = toAbilitySource attrs 1
      modifiers <- getModifiers iid
      when (assetClues attrs > 0 && CannotTakeControlOfClues `notElem` modifiers)
        $ pushAll [RemoveClues source (toTarget attrs) 1, GainClues iid source 1]
      pure a
    UseThisAbility iid (isSource attrs -> True) 2 -> do
      langneauPerdu <- genCard Story.langneauPerdu
      push $ ReadStory iid langneauPerdu ResolveIt (Just $ toTarget attrs)
      pure a
    _ -> JordanPerry <$> runMessage msg attrs
