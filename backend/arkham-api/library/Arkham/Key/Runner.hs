{-# OPTIONS_GHC -Wno-orphans #-}
module Arkham.Key.Runner (module X) where

import Arkham.Prelude

import Arkham.Classes as X
import Arkham.Helpers.Message as X
import Arkham.Id as X
import Arkham.Key.Types as X
import Arkham.Source as X
import Arkham.Target as X

instance RunMessage KeyAttrs where
  runMessage _ attrs = pure attrs
