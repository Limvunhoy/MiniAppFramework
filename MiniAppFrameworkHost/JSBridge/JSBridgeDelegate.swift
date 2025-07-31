import ObjectiveC
import UIKit

public protocol JSBridgeDelegate:AnyObject {
    func getProfile(completion: @escaping ([String : Any]?) -> Void)
    func getConfig(completion: @escaping ([String : Any]?) -> Void)
    func doPayment(args:[String : Any]?)
    func getDefaultAccount(completion: @escaping ([String : Any]?) -> Void) //
    func closeApp(args:[String : Any]?)
    func setBarTitle(barItem:[String : Any]?)
    func uploadFile(args:[String : Any]?,completion: @escaping ([String : Any]?) -> Void) //
    func openMap(args:[String : Any]?)
    func share(args:[String : Any]?)
    func backToHomePage()
    func addCalendar(args:[String : Any]?)
    func requestCurrentLocation()
    func download(args:[String : Any]?,completion: @escaping ([String : Any]?) -> Void)
    func openApp(args:[String : Any]?)
    func getNID(completion: @escaping ([String : Any]?) -> Void)
    func logError(completion: @escaping ([String : Any]?) -> Void)
    func onLoad(completion: @escaping ([String : Any]?) -> Void)
    func onViewAppInfo()
    func closePayment()
    func onEventCallback(type: String, data: [String: Any]?,completion: @escaping ([String : Any]?) -> Void)
//    func onCreateImageFileUri() -> Uri
}
