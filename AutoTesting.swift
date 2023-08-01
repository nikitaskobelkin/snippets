// The StorageManagerTests class contains asynchronous test cases for the StorageManager class. It validates the correctness of adding,
// fetching, removing, updating, and duplicating data in the storage. The tests use expectations to ensure the expected behavior of the
// StorageManager. The test cases cover various scenarios and provide meaningful assertions for validation.

final class StorageManagerTests: XCTestCase {
    private typealias Constants = FakeDatabaseConstants
    private var manager: StorageManagerProtocol!

    override func setUp() {
        let mockService = DatabaseService(FakeDatabaseStack().persistentContainer)
        manager = StorageManager(databaseService: mockService)
    }

    // MARK: - Add and fetch data

    func testAdding() async {
        let adding = expectation(description: "Adding")
        await manager.addBoxes(boxes: Constants.boxes)
        await manager.addGoods(goods: Constants.goods)
        adding.fulfill()
        wait(for: [adding], timeout: 4.0)
        let boxes = await manager.fetchBoxes()
        let goods = await manager.fetchGoods()

        // check adding
        XCTAssertEqual(boxes.count, Constants.boxes.count)
        XCTAssertEqual(goods.count, Constants.goods.count)

        // check that data is not empty
        let boxUid = Constants.boxes.map { $0.uid }.first
        XCTAssertTrue(boxes.contains(where: { $0.uid == boxUid }))
        XCTAssertNotNil(goods.first?.title)
    }

    // MARK: - Remove and update data

    func testUpdating() async {
        let adding = expectation(description: "Adding")
        let updating = expectation(description: "Updating")
        await manager.addBoxes(boxes: Constants.boxes)
        await manager.addGoods(goods: Constants.goods)
        adding.fulfill()
        guard let boxUid = Constants.boxes.first?.uid,
              var boxUpdate = Constants.boxes.last,
              let productUid = Constants.goods.first?.uid else {
            XCTFail(Constants.Errors.invalidData.rawValue)
            return
        }
        wait(for: [adding], timeout: 2.0)
        var boxes = await manager.fetchBoxes()
        var goods = await manager.fetchGoods()

        // check before updating
        XCTAssertEqual(boxes.count, Constants.boxes.count)
        XCTAssertEqual(goods.count, Constants.goods.count)

        boxUpdate.name = Constants.newBoxName

        await manager.removeBox(by: boxUid)
        await manager.removeProduct(by: productUid)
        await manager.updateBox(box: boxUpdate)
        boxes = await manager.fetchBoxes()
        goods = await manager.fetchGoods()
        updating.fulfill()
        wait(for: [updating], timeout: 2.0)

        // check removing
        XCTAssertEqual(boxes.count, Constants.boxes.count - 1)
        // check updating
        XCTAssertTrue(boxes.contains(where: { $0.name == Constants.newBoxName }))
        // first box includes all goods, so amount of goods should be 0
        XCTAssertEqual(goods.count, 0)

        let removingAll = expectation(description: "Removing all")
        await manager.removeAllBoxes()
        removingAll.fulfill()
        wait(for: [removingAll], timeout: 2.0)
        boxes = await manager.fetchBoxes()
        goods = await manager.fetchGoods()

        // check all removing
        XCTAssertTrue(boxes.isEmpty)
        XCTAssertTrue(goods.isEmpty)
    }

    // MARK: - Duplicate data

    func testDuplicating() async {
        let duplicating = expectation(description: "Duplicating")
        await manager.addBoxes(boxes: Constants.boxes)
        await manager.addGoods(goods: Constants.goods)
        guard let boxUid = Constants.boxes.first?.uid,
              let productUid = Constants.goods.first?.uid
        else {
            XCTFail(Constants.Errors.invalidData.rawValue)
            return
        }
        await manager.duplicateBox(by: boxUid, withGoods: true)
        await manager.duplicateProduct(by: productUid)
        duplicating.fulfill()
        wait(for: [duplicating], timeout: 4.0)
        let boxes = await manager.fetchBoxesWithGoods()
        let goods = await manager.fetchGoods()

        // check duplicated data
        XCTAssertTrue(
            boxes.contains(
                where: { $0.name.contains(StorageManagerConstants.copySuffix) && !$0.items.isEmpty }
            )
        )
        XCTAssertTrue(goods.contains(where: { $0.title.contains(StorageManagerConstants.copySuffix) }))
        XCTAssertEqual(boxes.count, Constants.boxes.count + 1)
        XCTAssertEqual(goods.count, Constants.goods.count * 2 + 1)
    }

    // MARK: - Fetch data

    func testFetching() async {
        let fetching = expectation(description: "Fetching")
        await manager.addBoxes(boxes: Constants.boxes)
        await manager.addGoods(goods: Constants.goods)
        guard let boxUid = Constants.boxes.first?.uid,
              let productUid = Constants.goods.first?.uid,
              let boxUidWithGoods = Constants.goods.first?.boxUid
        else {
            XCTFail(Constants.Errors.invalidData.rawValue)
            return
        }
        let box = await manager.fetchBoxes(by: boxUid)
        let product = await manager.fetchGoods(by: productUid)
        let goods = await manager.fetchGoods(byBox: boxUidWithGoods)
        let boxesQuantity = await manager.fetchBoxesQuantity()
        let goodsQuantity = await manager.fetchGoodsQuantity()

        fetching.fulfill()
        wait(for: [fetching], timeout: 4.0)

        // check fetching data
        XCTAssertEqual(box.first, Constants.boxes.first)
        XCTAssertEqual(product.first, Constants.goods.first)
        XCTAssertTrue(!goods.isEmpty)
        XCTAssertEqual(boxesQuantity, Constants.boxes.count)
        XCTAssertEqual(goodsQuantity, Constants.goods.count)
    }
}
