module Arkham.Types.Asset.Cards.ArcaneStudies
  ( ArcaneStudies(..)
  , arcaneStudies
  ) where

import Arkham.Prelude

import qualified Arkham.Asset.Cards as Cards
import Arkham.Types.Ability
import Arkham.Types.Asset.Attrs
import Arkham.Types.Asset.Helpers
import Arkham.Types.Asset.Runner
import Arkham.Types.Classes
import Arkham.Types.Cost
import Arkham.Types.Message
import Arkham.Types.Modifier
import Arkham.Types.SkillType
import Arkham.Types.Target
import Arkham.Types.Window

newtype ArcaneStudies = ArcaneStudies AssetAttrs
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

arcaneStudies :: AssetCard ArcaneStudies
arcaneStudies = asset ArcaneStudies Cards.arcaneStudies

instance HasModifiersFor env ArcaneStudies where
  getModifiersFor = noModifiersFor

ability :: Int -> AssetAttrs -> Ability
ability idx a = mkAbility a idx $ FastAbility $ ResourceCost 1

instance HasActions env ArcaneStudies where
  getActions iid (WhenSkillTest SkillWillpower) (ArcaneStudies a) =
    pure [ UseAbility iid (ability 1 a) | ownedBy a iid ]
  getActions iid (WhenSkillTest SkillIntellect) (ArcaneStudies a) =
    pure [ UseAbility iid (ability 2 a) | ownedBy a iid ]
  getActions _ _ _ = pure []

instance AssetRunner env => RunMessage env ArcaneStudies where
  runMessage msg a@(ArcaneStudies attrs) = case msg of
    UseCardAbility iid source _ 1 _ | isSource attrs source -> a <$ push
      (skillTestModifier
        attrs
        (InvestigatorTarget iid)
        (SkillModifier SkillWillpower 1)
      )
    UseCardAbility iid source _ 2 _ | isSource attrs source -> a <$ push
      (skillTestModifier
        attrs
        (InvestigatorTarget iid)
        (SkillModifier SkillIntellect 1)
      )
    _ -> ArcaneStudies <$> runMessage msg attrs
