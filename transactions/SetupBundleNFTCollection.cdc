import BundleNFTTool from 0x01

// This transaction configures a user's account
// to use the NFT contract by creating a new empty collection,
// storing it in their account storage, and publishing a capability
transaction {
    prepare(acct: AuthAccount) {

        // Create a new empty collection
        let collection <- BundleNFTTool.createEmptyBundleNFTCollection()

        // store the empty NFT Collection in account storage
        acct.save<@BundleNFTTool.BundleNFTCollection>(<-collection, to: /storage/BundleNFTCollection)

        log("Collection created for account 1")

        // create a public capability for the Collection
        acct.link<&{BundleNFTTool.BundleNFTReceiver}>(/public/BundleNFTReceiver, target: /storage/BundleNFTCollection)

        log("Capability created")
    }
}
 