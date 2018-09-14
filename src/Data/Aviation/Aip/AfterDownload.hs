{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeFamilies #-}

module Data.Aviation.Aip.AfterDownload(
  AfterDownload(..)
, nothingAfterDownload
, filePathAfterDownload
, hrefAfterDownload
, AfterDownloadAipCon
) where

import Control.Category((.))
import Control.Applicative(Applicative(pure, (<*>)))
import Control.Lens
import Control.Monad(Monad(return, (>>=)))
import Control.Monad.Trans.Class(MonadTrans(lift))
import Data.Aviation.Aip.AipCon(AipCon)
import Data.Aviation.Aip.Href(Href)
import Data.Functor(Functor(fmap))
import System.FilePath(FilePath)

newtype AfterDownload f a =
  AfterDownload
    (FilePath -> Href -> f a)

instance Functor f => Functor (AfterDownload f) where
  fmap f (AfterDownload x) =
    AfterDownload (\p h -> fmap f (x p h))

instance Applicative f => Applicative (AfterDownload f) where
  pure =
    AfterDownload . pure . pure . pure
  AfterDownload f <*> AfterDownload a =
    AfterDownload (\p h -> f p h <*> a p h)

instance Monad f => Monad (AfterDownload f) where
  return =
    pure
  AfterDownload x >>= f =
    AfterDownload (\p h -> x p h >>= \a -> let g = f a ^. _Wrapped in g p h)

instance MonadTrans AfterDownload where
  lift =
    AfterDownload . pure . pure

instance AfterDownload f a ~ x =>
  Rewrapped (AfterDownload g k) x

instance Wrapped (AfterDownload f k) where
  type Unwrapped (AfterDownload f k) =
      FilePath
      -> Href
      -> f k
  _Wrapped' =
    iso
      (\(AfterDownload x) -> x)
      AfterDownload

nothingAfterDownload ::
  Applicative f => AfterDownload f ()
nothingAfterDownload =
  pure ()

filePathAfterDownload ::
  Applicative f => AfterDownload f FilePath
filePathAfterDownload =
  AfterDownload (\p _ -> pure p)
  
hrefAfterDownload ::
  Applicative f => AfterDownload f Href
hrefAfterDownload =
  AfterDownload (\_ h -> pure h)

type AfterDownloadAipCon a =
  AfterDownload AipCon a
