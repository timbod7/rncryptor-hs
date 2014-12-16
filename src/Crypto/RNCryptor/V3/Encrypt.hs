{-# LANGUAGE BangPatterns #-}
module Crypto.RNCryptor.V3.Encrypt
  ( encrypt
  , encryptBlock
  , encryptStream
  ) where

import           Data.ByteString (ByteString)
import qualified Data.ByteString as B
import           Crypto.RNCryptor.Types
import           Crypto.RNCryptor.V3.Stream
import           Crypto.RNCryptor.Padding
import           Crypto.Cipher.AES
import           Data.Monoid
import qualified System.IO.Streams as S


--------------------------------------------------------------------------------
-- | Encrypt a raw Bytestring block. The function returns the encrypt text block
-- plus a new 'RNCryptorContext', which is needed because the IV needs to be
-- set to the last 16 bytes of the previous cipher text. (Thanks to Rob Napier
-- for the insight).
encryptBlock :: RNCryptorContext
             -> ByteString
             -> (RNCryptorContext, ByteString)
encryptBlock ctx clearText = 
  let cipherText  = encryptCBC (ctxCipher ctx) (rncIV . ctxHeader $ ctx) clearText
      !sz        = B.length clearText
      !newHeader = (ctxHeader ctx) { rncIV = (B.drop (sz - 16) clearText) }
      in (ctx { ctxHeader = newHeader }, cipherText)

--------------------------------------------------------------------------------
-- | Encrypt a message. Please be aware that this is a user-friendly
-- but dangerous function, in the sense that it will load the *ENTIRE* input in
-- memory. It's mostly suitable for small inputs like passwords. For large
-- inputs, where size exceeds the available memory, please use 'encryptStream'.
encrypt :: RNCryptorContext -> ByteString -> ByteString
encrypt ctx input =
  let hdr = ctxHeader ctx
      inSz = B.length input
      (_, clearText) = encryptBlock ctx (input <> pkcs7Padding blockSize inSz)
  in renderRNCryptorHeader hdr <> clearText <> (rncHMAC hdr $ mempty)

--------------------------------------------------------------------------------
-- | Efficiently encrypt an incoming stream of bytes.
encryptStream :: ByteString
              -- ^ The user key (e.g. password)
              -> S.InputStream ByteString
              -- ^ The input source (mostly likely stdin)
              -> S.OutputStream ByteString
              -- ^ The output source (mostly likely stdout)
              -> IO ()
encryptStream userKey inS outS = do
  hdr <- newRNCryptorHeader userKey
  let ctx = newRNCryptorContext userKey hdr
  S.write (Just $ renderRNCryptorHeader hdr) outS
  processStream ctx inS outS encryptBlock finaliseEncryption
  where
    finaliseEncryption lastBlock ctx = do
      let inSz = B.length lastBlock
          padding = pkcs7Padding blockSize inSz
      S.write (Just (snd $ encryptBlock ctx (lastBlock <> padding))) outS
      -- Finalise the block with the HMAC
      S.write (Just ((rncHMAC . ctxHeader $ ctx) mempty)) outS