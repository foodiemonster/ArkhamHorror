module Arkham.Types.Asset.Cards.CelaenoFragments where

import Arkham.Prelude

import Arkham.Asset.Cards qualified as Cards
import Arkham.Types.Asset.Attrs
import Arkham.Types.Id
import Arkham.Types.Modifier
import Arkham.Types.Query
import Arkham.Types.SkillType
import Arkham.Types.Target

newtype CelaenoFragments = CelaenoFragments AssetAttrs
  deriving anyclass (IsAsset, HasAbilities)
  deriving newtype (Show, Eq, Generic, ToJSON, FromJSON, Entity)

celaenoFragments :: AssetCard CelaenoFragments
celaenoFragments = hand CelaenoFragments Cards.celaenoFragments

instance HasCount CardCount env InvestigatorId => HasModifiersFor env CelaenoFragments where
  getModifiersFor _ (InvestigatorTarget iid) (CelaenoFragments attrs)
    | ownedBy attrs iid = do
      count' <- unCardCount <$> getCount iid
      pure
        . toModifiers attrs
        $ [ SkillModifier SkillIntellect 1 | count' >= 5 ]
        <> [ SkillModifier SkillWillpower 1 | count' >= 10 ]
        <> [ SkillModifier SkillIntellect 1 | count' >= 15 ]
  getModifiersFor _ _ _ = pure []

instance (AssetRunner env) => RunMessage env CelaenoFragments where
  runMessage msg (CelaenoFragments attrs) =
    CelaenoFragments <$> runMessage msg attrs
