{-# LANGUAGE OverloadedStrings #-}

module Main where

import           Control.Applicative
import           Control.Monad
import           Control.Monad.Trans
import           Data.Maybe
import           Data.Monoid
import qualified Data.ByteString.Char8 as BSC

import           Nagios.Check.RabbitMQ
import           Network.HTTP.Client
import           System.Environment

main :: IO ()
main = do
    opts <- parseOptions

    username <- maybe "" BSC.pack <$> lookupEnv "RABBIT_USER"
    password <- maybe "" BSC.pack <$> lookupEnv "RABBIT_PASS"

    let baseUrl = concat [ "http://", hostname opts, "/api/exchanges/%2F/", exchange opts ]
    authedRequest <- applyBasicAuth username password <$> parseUrl baseUrl

    let q_params = [ ("lengths_age",    Just "60")
                   , ("msg_rates_age",  Just "60")
                   , ("msg_rates_incr", Just "60")
                   ]
    let q_authedRequest = setQueryString q_params authedRequest

    print $ getUri q_authedRequest

    manager <- newManager defaultManagerSettings
    resp <- httpLbs q_authedRequest manager
    checkRawExchange (responseBody resp) opts
