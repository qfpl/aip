{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeFamilies #-}

module Data.Aviation.Aip.PerHref(
  PerHref(..)
, ioPerHref
, nothingPerHref
, hrefPerHref
, basedirPerHref
, PerHrefAipCon
) where

import Control.Category((.))
import Control.Applicative(Applicative(pure, (<*>)), Alternative((<|>), empty))
import Control.Lens hiding ((<.>))
import Control.Monad(Monad(return, (>>=)))
import Control.Monad.IO.Class(MonadIO(liftIO))
import Control.Monad.Trans.Class(MonadTrans(lift))
import Data.Aviation.Aip.AipCon(AipCon)
import Data.Aviation.Aip.Href(Href)
import Data.Functor(Functor(fmap))
import Data.Functor.Alt(Alt((<!>)))
import Data.Functor.Apply(Apply((<.>)))
import Data.Functor.Bind(Bind((>>-)))
import System.FilePath(FilePath)
import System.IO(IO)

newtype PerHref f a =
  PerHref
    (Href -> FilePath -> f a)

instance Functor f => Functor (PerHref f) where
  fmap f (PerHref x) =
    PerHref (\h d -> fmap f (x h d))

instance Apply f => Apply (PerHref f) where
  PerHref f <.> PerHref a =
    PerHref (\h d -> f h d <.> a h d)

instance Applicative f => Applicative (PerHref f) where
  pure =
    PerHref . pure . pure . pure
  PerHref f <*> PerHref a =
    PerHref (\h d -> f h d <*> a h d)

instance Bind f => Bind (PerHref f) where
  PerHref x >>- f =
    PerHref (\h d -> x h d >>- \a -> let g = f a ^. _Wrapped in g h d)

instance Monad f => Monad (PerHref f) where
  return =
    pure
  PerHref x >>= f =
    PerHref (\h d -> x h d >>= \a -> let g = f a ^. _Wrapped in g h d)

instance Alt f => Alt (PerHref f) where
  PerHref x <!> PerHref y =
    PerHref (\h d -> x h d <!> y h d)

instance Alternative f => Alternative (PerHref f) where
  PerHref x <|> PerHref y =
    PerHref (\h d -> x h d <|> y h d)
  empty =
    (PerHref . pure . pure) empty

instance MonadTrans PerHref where
  lift =
    PerHref . pure . pure

instance MonadIO f => MonadIO (PerHref f) where
  liftIO =
    PerHref . pure . pure . liftIO

instance PerHref f a ~ x =>
  Rewrapped (PerHref g k) x

instance Wrapped (PerHref f k) where
  type Unwrapped (PerHref f k) =
      Href
      -> FilePath
      -> f k
  _Wrapped' =
    iso
      (\(PerHref x) -> x)
      PerHref

ioPerHref ::
  MonadIO f =>
  (Href -> FilePath -> IO a)
  -> PerHref f a
ioPerHref k =
  PerHref (\h p -> liftIO (k h p))

nothingPerHref ::
  Applicative f =>
  PerHref f ()
nothingPerHref =
  pure ()

hrefPerHref ::
  Applicative f =>
  PerHref f Href
hrefPerHref =
  PerHref (\h _ -> pure h)

basedirPerHref ::
  Applicative f =>
  PerHref f FilePath
basedirPerHref =
  PerHref (\_ d -> pure d)

type PerHrefAipCon a =
  PerHref AipCon a