{-# LANGUAGE UndecidableInstances #-}
module Arkham.Types.Investigator.Cards.DexterDrake where

import Arkham.Types.Classes
import Arkham.Types.ClassSymbol
import Arkham.Types.Investigator.Attrs
import Arkham.Types.Investigator.Runner
import Arkham.Types.Message
import Arkham.Types.Stats
import Arkham.Types.Token
import Arkham.Types.Trait
import ClassyPrelude
import Data.Aeson

newtype DexterDrake = DexterDrake Attrs
  deriving newtype (Show, ToJSON, FromJSON)

instance HasModifiersFor env DexterDrake where
  getModifiersFor source target (DexterDrake attrs) =
    getModifiersFor source target attrs

dexterDrake :: DexterDrake
dexterDrake = DexterDrake $ baseAttrs
  "98016"
  "Dexter Drake"
  Mystic
  Stats
    { health = 6
    , sanity = 8
    , willpower = 5
    , intellect = 2
    , combat = 3
    , agility = 2
    }
  [Sorcerer, Veteran]

instance ActionRunner env => HasActions env DexterDrake where
  getActions i window (DexterDrake attrs) = getActions i window attrs

instance (InvestigatorRunner env) => RunMessage env DexterDrake where
  runMessage msg i@(DexterDrake attrs@Attrs {..}) = case msg of
    ResolveToken ElderSign iid | iid == investigatorId -> pure i
    _ -> DexterDrake <$> runMessage msg attrs
