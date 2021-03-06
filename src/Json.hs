{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DataKinds #-}

module Json where

import Data.Aeson
import Data.Aeson.Types
import qualified Data.Map as M
import qualified Data.IntMap as IM
import Data.Tree

import Types

instance FromJSON Profile where
  parseJSON = withObject "profile" $ \v -> do
      program <- v .: "program"
      totalTime <- v .: "total_time"
      rtsArgs <- v .: "rts_arguments"
      initCaps <- v .: "initial_capabilities"
      tickInterval <- v .: "tick_interval"
      totalAlloc <- v .: "total_alloc"
      totalTicks <- v .: "total_ticks"
      profile <- explicitParseField parseTree v "profile"
      let profileTree = mkTreeMap profile
      costCentres <- mkMap <$> v .: "cost_centres"
      return $ Profile
                program
                totalTime
                rtsArgs
                initCaps
                tickInterval
                totalAlloc
                totalTicks
                profile
                profileTree
                costCentres

    where
      mkMap list = IM.fromList [(ccId r, r) | r <- list]

      mkTreeMap node = IM.fromList $ mkTreePairs node

      mkTreePairs node =
        (singleRecordId $ rootLabel node, node) : concatMap mkTreePairs (subForest node)

parseTree :: Value -> Parser (Tree (ProfileRecord Individual))
parseTree = withObject "record" $ \v -> do
  root <- ProfileRecord
            <$> (IndividualId <$> v .: "id")
            <*> v .: "entries"
            <*> v .: "ticks"
            <*> v .: "alloc"
            <*> return Nothing
            <*> return Nothing
            <*> return Nothing
            <*> return Nothing
  children <- explicitParseField (listParser parseTree) v "children"
  return $ Node root children

instance FromJSON CostCentre where
  parseJSON = withObject "cost_centre" $ \v -> CostCentre
    <$> v .: "label"
    <*> v .: "id"
    <*> v .: "module"
    <*> v .: "src_loc"
    <*> v .: "is_caf"

