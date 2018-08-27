{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}

module Data.Aviation.Aip.AipDate(
  AipDate(..)
, AsAipDate(..)
, FoldAipDate(..)
, GetAipDate(..)
, SetAipDate(..)
, ManyAipDate(..)
, HasAipDate(..)
, IsAipDate(..)
) where

import Data.Aeson(FromJSON(parseJSON), ToJSON(toJSON))
import Papa hiding ((.=))

newtype AipDate =
  AipDate
    String
  deriving (Eq, Ord, Show)

instance FromJSON AipDate where
  parseJSON v =
    AipDate <$> parseJSON v

instance ToJSON AipDate where
  toJSON (AipDate x) =
    toJSON x

instance Semigroup AipDate where
  AipDate x <> AipDate y =
    AipDate (x <> y)

instance Monoid AipDate where
  mappend =
    (<>)
  mempty =
    AipDate mempty

instance Wrapped AipDate where
  type Unwrapped AipDate = String
  _Wrapped' =
    iso
      (\(AipDate x) -> x)
      AipDate

instance AipDate ~ a =>
  Rewrapped AipDate a

class AsAipDate a where
  _AipDate ::
    Prism' a AipDate
    
instance AsAipDate AipDate where
  _AipDate =
    id
  
instance AsAipDate String where
  _AipDate =
    from _Wrapped

class FoldAipDate a where
  _FoldAipDate ::
    Fold a AipDate
    
instance FoldAipDate AipDate where
  _FoldAipDate =
    id

instance FoldAipDate String where
  _FoldAipDate =
    from _Wrapped

class FoldAipDate a => GetAipDate a where
  _GetAipDate ::
    Getter a AipDate
    
instance GetAipDate AipDate where
  _GetAipDate =
    id

instance GetAipDate String where
  _GetAipDate =
    from _Wrapped

class SetAipDate a where
  _SetAipDate ::
    Setter' a AipDate
    
instance SetAipDate AipDate where
  _SetAipDate =
    id

instance SetAipDate String where
  _SetAipDate =
    from _Wrapped

class (FoldAipDate a, SetAipDate a) => ManyAipDate a where
  _ManyAipDate ::
    Traversal' a AipDate

instance ManyAipDate AipDate where
  _ManyAipDate =
    id

instance ManyAipDate String where
  _ManyAipDate =
    from _Wrapped

class (GetAipDate a, ManyAipDate a) => HasAipDate a where
  aipDate ::
    Lens' a AipDate

instance HasAipDate AipDate where
  aipDate =
    id

instance HasAipDate String where
  aipDate =
    from _Wrapped

class (HasAipDate a, AsAipDate a) => IsAipDate a where
  _IsAipDate ::
    Iso' a AipDate
    
instance IsAipDate AipDate where
  _IsAipDate =
    id

instance IsAipDate String where
  _IsAipDate =
    from _Wrapped
