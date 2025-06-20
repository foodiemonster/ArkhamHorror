{-# LANGUAGE TemplateHaskell #-}
module Arkham.Key.Types where

import Arkham.Prelude

import Arkham.Classes
import Arkham.Classes.RunMessage.Internal
import Arkham.Id
import Arkham.Json
import Arkham.Key
import Arkham.Name
import Arkham.Projection

-- | Whether a key is stable or unstable
data KeyStability = Stable | Unstable
  deriving stock (Show, Eq, Generic, Data)
  deriving anyclass (ToJSON, FromJSON)

data KeyAttrs = KeyAttrs
  { keyArkhamKey :: ArkhamKey
  , keyBearer :: Maybe InvestigatorId
  , keyStability :: KeyStability
  , keyMeta :: Value
  }
  deriving stock (Show, Eq)

makeLensesWith suffixedFields ''KeyAttrs

class
  ( Typeable a
  , ToJSON a
  , FromJSON a
  , Eq a
  , Show a
  , HasAbilities a
  , HasModifiersFor a
  , RunMessage a
  , Entity a
  , EntityId a ~ ArkhamKey
  , EntityAttrs a ~ KeyAttrs
  , RunType a ~ a
  ) =>
  IsKeyCard a

type KeyCard a = CardBuilder ArkhamKey a
