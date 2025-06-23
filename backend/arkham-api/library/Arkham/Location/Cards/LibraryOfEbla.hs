module Arkham.Location.Cards.LibraryOfEbla (libraryOfEbla, LibraryOfEbla(..)) where

import Arkham.Location.Cards qualified as Cards
import Arkham.Location.Import.Lifted

newtype LibraryOfEbla = LibraryOfEbla LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

libraryOfEbla :: LocationCard LibraryOfEbla
libraryOfEbla = location LibraryOfEbla Cards.libraryOfEbla 4 (PerPlayer 2)

-- Card code: 54033b
-- Class: Mythos
-- Type: Location
-- Traits: [Extradimensional]
-- Set: ReturnToTheCircleUndone
-- Encounter Set: ReturnToTheSecretName
-- Revealed Symbol: Squiggle
-- Revealed Connections: ['Square', 'Equals']
-- Victory: 1
-- Unrevealed Card Id: 54033
-- Unrevealed Symbol: Moon
-- Unrevealed Connections: ['Square']

-- Revealed Abilities:
-- [action]: Test [willpower] (5) to search the library for arcane lore. If you succeed, deal 3 damage to Nahab, even if she is out of play. (Group limit one success per game.)
-- Unrevealed Abilities:

-- TODO Card Text:


instance HasAbilities LibraryOfEbla where
  getAbilities (LibraryOfEbla attrs) = extendRevealed attrs []

instance RunMessage LibraryOfEbla where
  runMessage msg l@(LibraryOfEbla attrs) = runQueueT $ case msg of
    -- Example of using Projection helpers:
    -- shroudValue <- fieldJust LocationShroud attrs.id
    -- clueCount <- fieldMap LocationClues length attrs.id
    _ -> LibraryOfEbla <$> liftRunMessage msg attrs
