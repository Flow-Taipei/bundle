
import NonFungibleToken from 0x01

pub contract BundleNFTTool {

    // Declare the Bundle NFT resource type
    pub resource BundleNFT {
        // The unique ID that differentiates each Bundle NFT
        pub let id: UInt64

        // Place of NFT
        pub var InsideNFTs: @{UInt64: NonFungibleToken}

        // Initialize both fields in the init function
        init(initID: UInt64) {
            self.id = initID
            self.InsideNFTs  <- {}
        }
    }

    // We define this interface purely as a way to allow users
    // to create public, restricted references to their NFT Collection.
    // They would use this to only expose the deposit, getIDs,
    // and idExists fields in their Collection
    pub resource interface BundleNFTReceiver {

        //BundleNFT
        pub fun deposit(token: @BundleNFT)

        pub fun getIDs(): [UInt64]

        pub fun idExists(id: UInt64): Bool

        //BundleInside
        pub fun queryBundleNFTIDs(id: UInt64): [UInt64]
    }

    // The definition of the Collection resource that
    // holds the NFTs that a user owns
    pub resource BundleNFTCollection: BundleNFTReceiver {
        // dictionary of NFT conforming tokens
        // NFT is a resource type with an `UInt64` ID field
        pub var ownedNFTs: @{UInt64: BundleNFT}

        // Initialize the NFTs field to an empty collection
        init () {
            self.ownedNFTs <- {}
        }

        // withdraw 
        //
        // Function that removes an NFT from the collection 
        // and moves it to the calling context
        pub fun withdraw(withdrawID: UInt64): @BundleNFT {
            // If the NFT isn't found, the transaction panics and reverts
            let token <- self.ownedNFTs.remove(key: withdrawID)!

            return <-token
        }

        // deposit 
        //
        // Function that takes a NFT as an argument and 
        // adds it to the collections dictionary
        pub fun deposit(token: @BundleNFT) {
            // add the new token to the dictionary with a force assignment
            // if there is already a value at that key, it will fail and revert
            self.ownedNFTs[token.id] <-! token
        }

        // idExists checks to see if a NFT 
        // with the given ID exists in the collection
        pub fun idExists(id: UInt64): Bool {
            return self.ownedNFTs[id] != nil
        }

        // getIDs returns an array of the IDs that are in the collection
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }


        //Inside Bundle NFT Function
        pub fun queryBundleNFTIDs(id: UInt64): [UInt64] {
            return self.ownedNFTs[id].InsideNFTs.keys
        }

        pub fun depositToBundle(token: @NonFungibleToken, id: UInt64) {
            // add the new token to the dictionary with a force assignment
            // if there is already a value at that key, it will fail and revert
            self.ownedNFTs[id].InsideNFTs[token.id] <-! token
        }

        pub fun withdrawToBundle(withdrawID: UInt64, id: UInt64) {
            // If the NFT isn't found, the transaction panics and reverts
            let token <- self.ownedNFTs[id].InsideNFTs.remove(key: withdrawID)!

            return <-token
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    // creates a new empty Collection resource and returns it 
    pub fun createEmptyBundleNFTCollection(): @BundleNFTCollection {
        return <- create BundleNFTCollection()
    }

    // NFTMinter
    //
    // Resource that would be owned by an admin or by a smart contract 
    // that allows them to mint new NFTs when needed
    pub resource NFTMinter {

        // the ID that is used to mint NFTs
        // it is only incremented so that NFT ids remain
        // unique. It also keeps track of the total number of NFTs
        // in existence
        pub var idCount: UInt64

        init() {
            self.idCount = 1
        }

        // mintNFT 
        //
        // Function that mints a new NFT with a new ID
        // and returns it to the caller
        pub fun mintNFT(): @BundleNFT {

            // create a new NFT
            var newNFT <- create BundleNFT(initID: self.idCount)

            // change the id so that each ID is unique
            self.idCount = self.idCount + 1 as UInt64
            
            return <-newNFT
        }
    }

	init() {
		// store an empty NFT Collection in account storage
        self.account.save(<-self.createEmptyBundleNFTCollection(), to: /storage/BundleNFTCollection)

        // publish a reference to the Collection in storage
        self.account.link<&{BundleNFTReceiver}>(/public/BundleNFTReceiver, target: /storage/BundleNFTCollection)

        // store a minter resource in account storage
        self.account.save(<-create NFTMinter(), to: /storage/NFTMinter)
	}
}
 
