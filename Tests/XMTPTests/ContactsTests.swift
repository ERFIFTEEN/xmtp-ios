//
//  ContactsTests.swift
//
//
//  Created by Pat Nakajima on 12/8/22.
//

import XCTest
@testable import XMTPiOS
import XMTPTestHelpers

@available(iOS 15, *)
class ContactsTests: XCTestCase {
	func testNormalizesAddresses() async throws {
		let fixtures = await fixtures()
		try await fixtures.bobClient.ensureUserContactPublished()

		let bobAddressLowerCased = fixtures.bobClient.address.lowercased()
		let bobContact = try await fixtures.aliceClient.getUserContact(peerAddress: bobAddressLowerCased)

		XCTAssertNotNil(bobContact)
	}

	func testCanFindContact() async throws {
		let fixtures = await fixtures()

		try await fixtures.bobClient.ensureUserContactPublished()
		guard let contactBundle = try await fixtures.aliceClient.contacts.find(fixtures.bob.walletAddress) else {
			XCTFail("did not find contact bundle")
			return
		}

		XCTAssertEqual(contactBundle.walletAddress, fixtures.bob.walletAddress)
	}

	func testCachesContacts() async throws {
		let fixtures = await fixtures()

		try await fixtures.bobClient.ensureUserContactPublished()

		// Look up the first time
		_ = try await fixtures.aliceClient.contacts.find(fixtures.bob.walletAddress)

		try await fixtures.fakeApiClient.assertNoQuery {
			guard let contactBundle = try await fixtures.aliceClient.contacts.find(fixtures.bob.walletAddress) else {
				XCTFail("did not find contact bundle")
				return
			}

			XCTAssertEqual(contactBundle.walletAddress, fixtures.bob.walletAddress)
		}

		let hasContact = await fixtures.aliceClient.contacts.has(fixtures.bob.walletAddress)
		XCTAssert(hasContact)
	}

	func testAllowAddress() async throws {
		let fixtures = await fixtures()

		let contacts = fixtures.bobClient.contacts
		var result = await contacts.isAllowed(fixtures.alice.address)

		XCTAssertFalse(result)

		try await contacts.allow(addresses: [fixtures.alice.address])

		result = await contacts.isAllowed(fixtures.alice.address)
		XCTAssertTrue(result)
	}

	func testDenyAddress() async throws {
		let fixtures = await fixtures()

		let contacts = fixtures.bobClient.contacts
		var result = await contacts.isAllowed(fixtures.alice.address)

		XCTAssertFalse(result)

		try await contacts.deny(addresses: [fixtures.alice.address])

		result = await contacts.isDenied(fixtures.alice.address)
		XCTAssertTrue(result)
	}
    
    func testHandleMultipleAddresses() async throws {
        let fixtures = await fixtures()
        let caro = try PrivateKey.generate()
        let fakeApiClient = FakeApiClient()
        let caroClient = try await Client.create(account: caro, apiClient: fakeApiClient)

        let contacts = fixtures.bobClient.contacts
        var result = await contacts.isAllowed(fixtures.alice.address)
        XCTAssertFalse(result)
        result = await contacts.isAllowed(caroClient.address)
        XCTAssertFalse(result)

        try await contacts.deny(addresses: [fixtures.alice.address, caroClient.address])

        var aliceResult = await contacts.isDenied(fixtures.alice.address)
        XCTAssertTrue(aliceResult)
        var caroResult = await contacts.isDenied(fixtures.alice.address)
        XCTAssertTrue(caroResult)
        try await contacts.allow(addresses: [fixtures.alice.address, caroClient.address])
        aliceResult = await contacts.isAllowed(fixtures.alice.address)
        XCTAssertTrue(aliceResult)
        caroResult = await contacts.isAllowed(fixtures.alice.address)
        XCTAssertTrue(caroResult)
    }
}
