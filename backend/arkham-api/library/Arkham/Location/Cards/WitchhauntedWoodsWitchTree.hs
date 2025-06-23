module Arkham.Location.Cards.WitchhauntedWoodsWitchTree (witchhauntedWoodsWitchTree, WitchhauntedWoodsWitchTree(..)) where

import Arkham.Location.Cards qualified as Cards
import Arkham.Location.Import.Lifted

newtype WitchhauntedWoodsWitchTree = WitchhauntedWoodsWitchTree LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

witchhauntedWoodsWitchTree :: LocationCard WitchhauntedWoodsWitchTree
witchhauntedWoodsWitchTree = location WitchhauntedWoodsWitchTree Cards.witchhauntedWoodsWitchTree 4 (PerPlayer 1)

-- Card code: 54019b
-- Class: Mythos
-- Type: Location
-- Traits: [Woods]
-- Set: ReturnToTheCircleUndone
-- Encounter Set: ReturnToTheWitchingHour
-- Revealed Symbol: Squiggle
-- Revealed Connections: ['Squiggle', 'Plus']
-- Victory: 1
-- Unrevealed Card Id: 54019
-- Unrevealed Symbol: Squiggle
-- Unrevealed Connections: ['Squiggle', 'Plus']

-- Revealed Abilities:
-- [free] Take 1 direct damage and 1 direct horror: Choose an investigator at a different Witch-Haunted Woods. That investigator heals 1 damage and 1 horror. (Group limit once per round.)
-- Unrevealed Abilities:

-- TODO Card Text:


instance HasAbilities WitchhauntedWoodsWitchTree where
  getAbilities (WitchhauntedWoodsWitchTree attrs) = extendRevealed attrs []

instance RunMessage WitchhauntedWoodsWitchTree where
  runMessage msg l@(WitchhauntedWoodsWitchTree attrs) = runQueueT $ case msg of
    -- Example of using Projection helpers:
    -- shroudValue <- fieldJust LocationShroud attrs.id
    -- clueCount <- fieldMap LocationClues length attrs.id
    _ -> WitchhauntedWoodsWitchTree <$> liftRunMessage msg attrs
