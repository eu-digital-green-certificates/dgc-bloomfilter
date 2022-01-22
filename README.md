<h1 align="center">
   Standardized Bloom Filter Implementations
</h1>

<p align="center">
  <a href="https://github.com/eu-digital-green-certificates/dgc-bloomfilter/actions/workflows/ci-main.yml" title="ci-main.yml">
    <img src="https://github.com/eu-digital-green-certificates/dgc-bloomfilter/actions/workflows/ci-main.yml/badge.svg">
  </a>
  <a href="/../../commits/" title="Last Commit">
    <img src="https://img.shields.io/github/last-commit/eu-digital-green-certificates/dgc-bloomfilter?style=flat">
  </a>
  <a href="/../../issues" title="Open Issues">
    <img src="https://img.shields.io/github/issues/eu-digital-green-certificates/dgc-bloomfilter?style=flat">
  </a>
  <a href="./LICENSE" title="License">
    <img src="https://img.shields.io/badge/License-Apache%202.0-green.svg?style=flat">
  </a>
</p>

<p align="center">
  <a href="#about">About</a> •
  <a href="#development">Development</a> •
  <a href="#documentation">Documentation</a> •
  <a href="#support-and-feedback">Support</a> •
  <a href="#how-to-contribute">Contribute</a> •
  <a href="#licensing">Licensing</a>
</p>

## About

This repository contains the source code of standardized bloom filter implementationn in different languages for the usage in covid associated applications. The code base itself is not bound to Covid Certificates itself and can be used in other applications as well. 

Main goal of the standardization is, to have an 1:1 crossplatform behavior in swift, java, python, javascript, kotlin, nodejs, C#, Go and Other languages which are used in covid applications. (Please contribute language implementations if possible). Currently available:


- [x] Java
- [x] Swift
- [ ] Kotlin
- [ ] C#
- [ ] Javascript
- [ ] Nodejs
- [ ] Go
- [ ] Python


To standardize the implementation a set of abstract testdata and a standardized data format is created to align all implementations in the behavior. 



Important Links: 
  
   * [Basics](https://en.wikipedia.org/wiki/Bloom_filter) - Basic Wikipedia Page about Bloom Filters
   * [Mathematics](https://www.di-mgt.com.au/bloom-filter.html) - Background Knowledge about Filters
   * [Python Implementation](https://www.geeksforgeeks.org/bloom-filters-introduction-and-python-implementation/) - Python Example of Bloom Filters
   * [Google Java Implementation](https://github.com/google/guava/blob/7031494cbb29f3443a85303bdf14389ae6a5b58e/android/guava/src/com/google/common/hash/BloomFilter.java#L463) - Guava Filter of google.
   * [Calculator](https://www.di-mgt.com.au/bloom-calculator.html) - For size Calculation
   * [Calculator 2](https://hur.st/bloomfilter/) - For size Calculation

# Important Notes

To align the implementations, some points must be considered during the implementation: 

- The logarithmus function is logarithmus naturalis (base e)
- all bytes are ordered in Big Endian
- the bits will be count from left to right (10000000 --> 010000000 --> 001000000 etc.)
- Use Bit Masks for comparing e.g. currentByte & 0x000010000 and combine the results byte for byte
- All bits are grouped in blocks of 4 Byte (Array of 4 Byte Objects, not an Array Single Bits --> more space efficent)
- It doesnt matter which blocksize is used in a language (unsigned or signed is also not important), the only important thing is the bitshifting capability for a single bit (no filling during shift).
- Maximum of the Filter must be an array containing 4 Byte values with an amount of maximum 4 Bytes (e.g. int [] with i=Integer.MAX_VALUE)
- Hash Function is currently SHA256 (Default: 0 in Dataformat), because other Functions like MUMUR_3 are not in every language available. If more Performance is necessary, please provide Enhancement Issues with your Change Proposals (or better a Pull Request)
- It's only one hash function used with a seed within multiple rounds. Different hash functions are not necessary in terms of uniformity

# Data Format

The data format is a serialized byte stream with the following structure in Big Endian Format:

|Pos| Byte                                     |   Field | Description                                                        |
|---| -----------------------------------------|---------|--------------------------------------------------------------------|
|0-1| 2 Byte signed Number (-32,768 to 32,767) | Version | Number which describes the current version of the used Data Format.|
|2| 1 Byte signed Number       (-128 to 127) | Used Hashing | Number of the used Hashalgorithm (TOB) or Hash Strategy. Default is 0 for Uniform SHA256 Hashing|
|3| 1 Byte signed Number (-128 to 127) | k | Amount of used Hash function calculations|
|4-7| 4 Byte signed Decimal (7 Digits) | p | Probility Rate|
|8-11| 4 Byte signed Number (-2,147,483,648 to 2,147,483,647) | n| Amount of Elements for which the filter was constructed|
|12-15| 4 Byte signed Number (-2,147,483,648 to 2,147,483,647) | Current Filter Size | Amount of Elements which the filter currently carries|
|16-21| 4 Byte signed Number (-2,147,483,648 to 2,147,483,647) | Data Length of Filter | Amount of Bytes of the Filter|
|21-*| 4 Byte signed Number (-2,147,483,648 to 2,147,483,647) | Filter | Bytes of the Bloom Filter|
     

## Support and feedback

The following channels are available for discussions, feedback, and support requests:

| Type                     | Channel                                                |
| ------------------------ | ------------------------------------------------------ |
| **Issues**    | <a href="/../../issues" title="Open Issues"><img src="https://img.shields.io/github/issues/eu-digital-green-certificates/dgca-validation-service?style=flat"></a>  |
| **Other requests**    | <a href="mailto:opensource@telekom.de" title="Email DGC Team"><img src="https://img.shields.io/badge/email-DGC%20team-green?logo=mail.ru&style=flat-square&logoColor=white"></a>   |

## How to contribute  

Contribution and feedback is encouraged and always welcome. For more information about how to contribute, the project structure, 
as well as additional contribution information, see our [Contribution Guidelines](./CONTRIBUTING.md). By participating in this 
project, you agree to abide by its [Code of Conduct](./CODE_OF_CONDUCT.md) at all times.

## Licensing

Copyright (C) 2021 T-Systems International GmbH and all other contributors

Licensed under the **Apache License, Version 2.0** (the "License"); you may not use this file except in compliance with the License.

You may obtain a copy of the License at https://www.apache.org/licenses/LICENSE-2.0.

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" 
BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the [LICENSE](./LICENSE) for the specific 
language governing permissions and limitations under the License.
