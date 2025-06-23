module Arkham.Location.Cards.Uptown (uptown, Uptown(..)) where

import Arkham.Location.Cards qualified as Cards
import Arkham.Location.Import.Lifted

newtype Uptown = Uptown LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

uptown :: LocationCard Uptown
uptown = location Uptown Cards.uptown 2 (Static 0)

-- Card code: 54053b
-- Class: Mythos
-- Type: Location
-- Traits: [Arkham]
-- Set: ReturnToTheCircleUndone
-- Encounter Set: ReturnToInTheClutchesOfChaos
-- Revealed Symbol: Plus
-- Revealed Connections: ['Square', 'Triangle', 'Moon']
-- Victory: 
-- Unrevealed Card Id: 54053
-- Unrevealed Symbol: Plus
-- Unrevealed Connections: ['Square', 'Triangle', 'Moon']

-- Revealed Abilities:
-- [action]: Move any number of breaches from Uptown to the current act. Then, test [agility] (X), where X is the number of breaches moved. For each point you fail by, take 1 damage.
-- Unrevealed Abilities:

-- TODO Card Text:


instance HasAbilities Uptown where
  getAbilities (Uptown attrs) = extendRevealed attrs []

instance RunMessage Uptown where
  runMessage msg l@(Uptown attrs) = runQueueT $ case msg of
    -- Example of using Projection helpers:
    -- shroudValue <- fieldJust LocationShroud attrs.id
    -- clueCount <- fieldMap LocationClues length attrs.id
    _ -> Uptown <$> liftRunMessage msg attrs
