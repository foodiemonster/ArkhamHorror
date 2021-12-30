module Arkham.Enemy.Cards.StealthyByakhee
  ( stealthyByakhee
  , StealthyByakhee(..)
  ) where

import Arkham.Prelude

import Arkham.Enemy.Cards qualified as Cards
import Arkham.Classes
import Arkham.Enemy.Runner

newtype StealthyByakhee = StealthyByakhee EnemyAttrs
  deriving anyclass (IsEnemy, HasModifiersFor env)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity, HasAbilities)

stealthyByakhee :: EnemyCard StealthyByakhee
stealthyByakhee =
  enemy StealthyByakhee Cards.stealthyByakhee (5, Static 2, 3) (2, 1)

instance EnemyRunner env => RunMessage env StealthyByakhee where
  runMessage msg (StealthyByakhee attrs) =
    StealthyByakhee <$> runMessage msg attrs
