module Arkham.Location.Cards.SouthChurch (southChurch, SouthChurch(..)) where

import Arkham.Location.Cards qualified as Cards
import Arkham.Location.Import.Lifted

newtype SouthChurch = SouthChurch LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

southChurch :: LocationCard SouthChurch
southChurch = location SouthChurch Cards.southChurch 3 (Static 0)

-- Card code: 54054b
-- Class: Mythos
-- Type: Location
-- Traits: [Arkham]
-- Set: ReturnToTheCircleUndone
-- Encounter Set: ReturnToInTheClutchesOfChaos
-- Revealed Symbol: Diamond
-- Revealed Connections: ['Square']
-- Victory: 
-- Unrevealed Card Id: 54054
-- Unrevealed Symbol: Diamond
-- Unrevealed Connections: ['Square']

-- Revealed Abilities:
-- [action] [action]: Move all breaches from South Church to the current act. [action]: <b>Resign.</b> You hide through the night.
-- Unrevealed Abilities:

-- TODO Card Text:


instance HasAbilities SouthChurch where
  getAbilities (SouthChurch attrs) = extendRevealed attrs []

instance RunMessage SouthChurch where
  runMessage msg l@(SouthChurch attrs) = runQueueT $ case msg of
    -- Example of using Projection helpers:
    -- shroudValue <- fieldJust LocationShroud attrs.id
    -- clueCount <- fieldMap LocationClues length attrs.id
    _ -> SouthChurch <$> liftRunMessage msg attrs
