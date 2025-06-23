module Arkham.Location.Cards.MerchantDistrict (merchantDistrict, MerchantDistrict(..)) where

import Arkham.Location.Cards qualified as Cards
import Arkham.Location.Import.Lifted

newtype MerchantDistrict = MerchantDistrict LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

merchantDistrict :: LocationCard MerchantDistrict
merchantDistrict = location MerchantDistrict Cards.merchantDistrict 4 (Static 0)

-- Card code: 54055b
-- Class: Mythos
-- Type: Location
-- Traits: [Arkham]
-- Set: ReturnToTheCircleUndone
-- Encounter Set: ReturnToInTheClutchesOfChaos
-- Revealed Symbol: Triangle
-- Revealed Connections: ['Circle', 'Square', 'Plus']
-- Victory: 0
-- Unrevealed Card Id: 54055
-- Unrevealed Symbol: Triangle
-- Unrevealed Connections: ['Circle', 'Square', 'Plus']

-- Revealed Abilities:
-- [action]: Move 1 breach from Merchant District to the current act. You may spend any number of charges, secrets, supplies, or ammo from any assets you control to move that many additional breaches.
-- Unrevealed Abilities:

-- TODO Card Text:


instance HasAbilities MerchantDistrict where
  getAbilities (MerchantDistrict attrs) = extendRevealed attrs []

instance RunMessage MerchantDistrict where
  runMessage msg l@(MerchantDistrict attrs) = runQueueT $ case msg of
    -- Example of using Projection helpers:
    -- shroudValue <- fieldJust LocationShroud attrs.id
    -- clueCount <- fieldMap LocationClues length attrs.id
    _ -> MerchantDistrict <$> liftRunMessage msg attrs
