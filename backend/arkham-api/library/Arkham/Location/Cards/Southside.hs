module Arkham.Location.Cards.Southside (southside, Southside(..)) where

import Arkham.Location.Cards qualified as Cards
import Arkham.Location.Import.Lifted

newtype Southside = Southside LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

southside :: LocationCard Southside
southside = location Southside Cards.southside 3 (Static 0)

-- Card code: 54052b
-- Class: Mythos
-- Type: Location
-- Traits: [Arkham, Central]
-- Set: ReturnToTheCircleUndone
-- Encounter Set: ReturnToInTheClutchesOfChaos
-- Revealed Symbol: Square
-- Revealed Connections: ['Circle', 'Triangle', 'Plus', 'T', 'Diamond']
-- Victory: 
-- Unrevealed Card Id: 54052
-- Unrevealed Symbol: Square
-- Unrevealed Connections: ['Circle', 'Triangle', 'Plus', 'T', 'Diamond']

-- Revealed Abilities:
-- [action]: <b>Evade.</b> Use this ability on any enemy in play or in the encounter discard pile. If you fail, that enemy attacks you <i>(even if it is not in play)</i>. If you succeed, instead of evading the chosen enemy, move all breaches from Southside to the current act.
-- Unrevealed Abilities:

-- TODO Card Text:


instance HasAbilities Southside where
  getAbilities (Southside attrs) = extendRevealed attrs []

instance RunMessage Southside where
  runMessage msg l@(Southside attrs) = runQueueT $ case msg of
    -- Example of using Projection helpers:
    -- shroudValue <- fieldJust LocationShroud attrs.id
    -- clueCount <- fieldMap LocationClues length attrs.id
    _ -> Southside <$> liftRunMessage msg attrs
