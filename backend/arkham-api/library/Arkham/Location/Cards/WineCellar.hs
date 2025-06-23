module Arkham.Location.Cards.WineCellar (wineCellar, WineCellar(..)) where

import Arkham.Location.Cards qualified as Cards
import Arkham.Location.Import.Lifted

newtype WineCellar = WineCellar LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

wineCellar :: LocationCard WineCellar
wineCellar = location WineCellar Cards.wineCellar 5 (PerPlayer 1)

-- Card code: 54028b
-- Class: Mythos
-- Type: Location
-- Traits: []
-- Set: ReturnToTheCircleUndone
-- Encounter Set: ReturnToAtDeathSDoorstep
-- Revealed Symbol: Hourglass
-- Revealed Connections: ['T']
-- Victory: 0
-- Unrevealed Card Id: 54028
-- Unrevealed Symbol: Hourglass
-- Unrevealed Connections: ['T']

-- Revealed Abilities:
-- [action] You disturb the tranquility of this quiet place in search of evidence. Discard cards from the top of the encounter deck until a [[Monster]] enemy is discarded. Set that enemy aside, out of play. Then gain 2 clues (from the token pool). (Group limit once per game.)
-- Unrevealed Abilities:
-- Victorian Halls is connected to Wine Cellar.
-- TODO Card Text:


instance HasAbilities WineCellar where
  getAbilities (WineCellar attrs) = extendRevealed attrs []

instance RunMessage WineCellar where
  runMessage msg l@(WineCellar attrs) = runQueueT $ case msg of
    -- Example of using Projection helpers:
    -- shroudValue <- fieldJust LocationShroud attrs.id
    -- clueCount <- fieldMap LocationClues length attrs.id
    _ -> WineCellar <$> liftRunMessage msg attrs
