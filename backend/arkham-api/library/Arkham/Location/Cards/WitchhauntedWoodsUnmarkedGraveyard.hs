module Arkham.Location.Cards.WitchhauntedWoodsUnmarkedGraveyard (witchhauntedWoodsUnmarkedGraveyard, WitchhauntedWoodsUnmarkedGraveyard(..)) where

import Arkham.Location.Cards qualified as Cards
import Arkham.Location.Import.Lifted

newtype WitchhauntedWoodsUnmarkedGraveyard = WitchhauntedWoodsUnmarkedGraveyard LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

witchhauntedWoodsUnmarkedGraveyard :: LocationCard WitchhauntedWoodsUnmarkedGraveyard
witchhauntedWoodsUnmarkedGraveyard = location WitchhauntedWoodsUnmarkedGraveyard Cards.witchhauntedWoodsUnmarkedGraveyard 1 (PerPlayer 2)

-- Card code: 54020b
-- Class: Mythos
-- Type: Location
-- Traits: [Woods]
-- Set: ReturnToTheCircleUndone
-- Encounter Set: ReturnToTheWitchingHour
-- Revealed Symbol: Squiggle
-- Revealed Connections: ['Squiggle', 'Plus']
-- Victory: 1
-- Unrevealed Card Id: 54020
-- Unrevealed Symbol: Squiggle
-- Unrevealed Connections: ['Squiggle', 'Plus']

-- Revealed Abilities:
-- <b>Forced</b> - When you discover the last clue from this location: Draw the topmost [[Hex]] treachery in the encounter discard pile. (If you cannot, instead discard cards from the top of the encounter deck until a [[Hex]] treachery is discarded, and draw it.)
-- Unrevealed Abilities:

-- TODO Card Text:


instance HasAbilities WitchhauntedWoodsUnmarkedGraveyard where
  getAbilities (WitchhauntedWoodsUnmarkedGraveyard attrs) = extendRevealed attrs []

instance RunMessage WitchhauntedWoodsUnmarkedGraveyard where
  runMessage msg l@(WitchhauntedWoodsUnmarkedGraveyard attrs) = runQueueT $ case msg of
    -- Example of using Projection helpers:
    -- shroudValue <- fieldJust LocationShroud attrs.id
    -- clueCount <- fieldMap LocationClues length attrs.id
    _ -> WitchhauntedWoodsUnmarkedGraveyard <$> liftRunMessage msg attrs
