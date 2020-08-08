{-# LANGUAGE UndecidableInstances #-}
module Arkham.Types.Enemy.Cards.GhoulMinion where

import Arkham.Json
import Arkham.Types.Classes
import Arkham.Types.Enemy.Attrs
import Arkham.Types.Enemy.Runner
import Arkham.Types.EnemyId
import Arkham.Types.GameValue
import ClassyPrelude

newtype GhoulMinion = GhoulMinion Attrs
  deriving newtype (Show, ToJSON, FromJSON)

ghoulMinion :: EnemyId -> GhoulMinion
ghoulMinion uuid = GhoulMinion $ (baseAttrs uuid "01160")
  { enemyHealthDamage = 1
  , enemySanityDamage = 1
  , enemyFight = 2
  , enemyHealth = Static 2
  , enemyEvade = 2
  }

instance (EnemyRunner env) => RunMessage env GhoulMinion where
  runMessage msg (GhoulMinion attrs) = GhoulMinion <$> runMessage msg attrs
