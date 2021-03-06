[![Build Status](https://travis-ci.org/RNCryptor/rncryptor-hs.svg?branch=master)](https://travis-ci.org/RNCryptor/rncryptor-hs)

# Haskell Implementation of the RNCryptor spec
This library implements the specification for the [RNCryptor](https://github.com/RNCryptor)
encrypted file format by Rob Napier.

# Current Supported Versions
* V3 - [Spec](https://github.com/RNCryptor/RNCryptor-Spec/blob/master/RNCryptor-Spec-v3.md)

# TODO
- [X] HMAC Validation
- [ ] Test vectors testing
- [ ] Profiling & optimisations

# Contributors (Sorted by name)
- Alfredo Di Napoli (creator and maintainer)
- Rob Napier (gave me the key insight to use the previous cipher text as IV for the new block)
- Tom Titchener (added support for HMAC validation)

# Contributions
This library scratches my own itches, but please fork away!
Pull requests are encouraged.
