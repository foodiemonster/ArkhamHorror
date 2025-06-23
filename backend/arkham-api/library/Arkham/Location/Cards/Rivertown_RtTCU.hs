module Arkham.Location.Cards.Rivertown (rivertown, Rivertown(..)) where

import Arkham.Location.Cards qualified as Cards
import Arkham.Location.Import.Lifted

newtype Rivertown = Rivertown LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

rivertown :: LocationCard Rivertown
rivertown = location Rivertown Cards.rivertown 2 (Static 0)

-- Card code: 54051b
-- Class: Mythos
-- Type: Location
-- Traits: [Arkham]
-- Set: ReturnToTheCircleUndone
-- Encounter Set: ReturnToInTheClutchesOfChaos
-- Revealed Symbol: Circle
-- Revealed Connections: ['Square', 'Triangle', 'T']
-- Victory: 
-- Unrevealed Card Id: 54051
-- Unrevealed Symbol: Circle
-- Unrevealed Connections: ['Square', 'Triangle', 'T']

-- Revealed Abilities:
-- [action]: Move any number of breaches from Rivertown to the current act. Then, test [intellect] (X), where X is 1 more than the number of breaches moved. For each point you fail by, either take 1 horror or 1 damage.
-- Unrevealed Abilities:

-- TODO Card Text:


instance HasAbilities Rivertown where
  getAbilities (Rivertown attrs) = extendRevealed attrs []

instance RunMessage Rivertown where
  runMessage msg l@(Rivertown attrs) = runQueueT $ case msg of
    -- Example of using Projection helpers:
    -- shroudValue <- fieldJust LocationShroud attrs.id
    -- clueCount <- fieldMap LocationClues length attrs.id
    _ -> Rivertown <$> liftRunMessage msg attrs
