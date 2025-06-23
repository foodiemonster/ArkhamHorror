module Arkham.Location.Cards.FrenchHill (frenchHill, FrenchHill(..)) where

import Arkham.Location.Cards qualified as Cards
import Arkham.Location.Import.Lifted

newtype FrenchHill = FrenchHill LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

frenchHill :: LocationCard FrenchHill
frenchHill = location FrenchHill Cards.frenchHill 2 (Static 0)

-- Card code: 54050b
-- Class: Mythos
-- Type: Location
-- Traits: [Arkham]
-- Set: ReturnToTheCircleUndone
-- Encounter Set: ReturnToInTheClutchesOfChaos
-- Revealed Symbol: T
-- Revealed Connections: ['Circle', 'Square', 'Star']
-- Victory: 
-- Unrevealed Card Id: 54050
-- Unrevealed Symbol: T
-- Unrevealed Connections: ['Circle', 'Square', 'Star']

-- Revealed Abilities:
-- [action]: Move any number of breaches from French Hill to the current act. Then, test [willpower] (X), where X is the number of breaches moved. For each point you fail by, take 1 horror.
-- Unrevealed Abilities:

-- TODO Card Text:


instance HasAbilities FrenchHill where
  getAbilities (FrenchHill attrs) = extendRevealed attrs []

instance RunMessage FrenchHill where
  runMessage msg l@(FrenchHill attrs) = runQueueT $ case msg of
    -- Example of using Projection helpers:
    -- shroudValue <- fieldJust LocationShroud attrs.id
    -- clueCount <- fieldMap LocationClues length attrs.id
    _ -> FrenchHill <$> liftRunMessage msg attrs
