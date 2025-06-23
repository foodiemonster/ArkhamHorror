module Arkham.Location.Cards.WineCellarSpectral (WineCellarSpectral, WineCellarSpectral(..)) where

import Arkham.Location.Cards qualified as Cards
import Arkham.Location.Import.Lifted

newtype WineCellarSpectral = WineCellarSpectral LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

WineCellarSpectral :: LocationCard WineCellarSpectral
WineCellarSpectral = location WineCellarSpectral Cards.WineCellarSpectral 5 (PerPlayer 2)

-- Card code: 54028b
-- Class: Mythos
-- Type: Location
-- Traits: [Spectral]
-- Set: ReturnToTheCircleUndone
-- Encounter Set: ReturnToAtDeathSDoorstep
-- Revealed Symbol: Hourglass
-- Revealed Connections: ['T']
-- Victory: 0
-- Unrevealed Card Id: 54028
-- Unrevealed Symbol: Hourglass
-- Unrevealed Connections: ['T']

-- Revealed Abilities:
-- [reaction] After you successfully investigate the Wine Cellar: Either discover 1 additional clue, or remove 1 doom from a [[Silver Twilight]] enemy in play. --Haunted</b> - You must either place 1 doom on a [[Silver Twilight]] enemy in play, or take 1 direct horror.
-- Unrevealed Abilities:
-- Victorian Halls is connected to Wine Cellar.
-- TODO Card Text:


instance HasAbilities WineCellarSpectral where
  getAbilities (WineCellarSpectral attrs) = extendRevealed attrs []

instance RunMessage WineCellarSpectral where
  runMessage msg l@(WineCellarSpectral attrs) = runQueueT $ case msg of
    -- Example of using Projection helpers:
    -- shroudValue <- fieldJust LocationShroud attrs.id
    -- clueCount <- fieldMap LocationClues length attrs.id
    _ -> WineCellarSpectral <$> liftRunMessage msg attrs
