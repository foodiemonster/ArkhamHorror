module Arkham.Location.Cards.The9thWard (the9thWard, The9thWard(..)) where

import Arkham.Location.Cards qualified as Cards
import Arkham.Location.Import.Lifted

newtype The9thWard = The9thWard LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

the9thWard :: LocationCard The9thWard
the9thWard = location The9thWard Cards.the9thWard 5 (PerPlayer 1)

-- Card code: 54032b
-- Class: Mythos
-- Type: Location
-- Traits: [Extradimensional]
-- Set: ReturnToTheCircleUndone
-- Encounter Set: ReturnToTheSecretName
-- Revealed Symbol: Moon
-- Revealed Connections: ['Square']
-- Victory: 0
-- Unrevealed Card Id: 54032
-- Unrevealed Symbol: Moon
-- Unrevealed Connections: ['Square']

-- Revealed Abilities:
-- [action]: --Investigate.</b> Investigate using [agility] instead of [intellect]. If you succeed, after discovering clues, you may move to any [[Extradimensional]] location. --Haunted</b> - You cannot leave The 9th Ward this round. During your turn, reduce the shroud value of The 9th Ward by 1.
-- Unrevealed Abilities:

-- TODO Card Text:


instance HasAbilities The9thWard where
  getAbilities (The9thWard attrs) = extendRevealed attrs []

instance RunMessage The9thWard where
  runMessage msg l@(The9thWard attrs) = runQueueT $ case msg of
    -- Example of using Projection helpers:
    -- shroudValue <- fieldJust LocationShroud attrs.id
    -- clueCount <- fieldMap LocationClues length attrs.id
    _ -> The9thWard <$> liftRunMessage msg attrs
