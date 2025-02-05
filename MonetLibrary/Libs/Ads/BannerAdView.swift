//
//  BannerAdView.swift
//  MonetLibrary
//
//  Created by Hoang on 5/2/25.
//
import SwiftUI
import GoogleMobileAds

struct BannerAdView: UIViewRepresentable {
    let bannerConifg: BannerConfig
    let adUnitIDs: [String]
    let loadType: LoadType
    init(config: BannerConfig) {
        bannerConifg = config
        adUnitIDs = config.ids
        loadType = config.loadType
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UIView {
        let containerView = UIView(frame: .zero)
        // Lưu containerView vào coordinator để thêm/xoá subview khi cần
        context.coordinator.containerView = containerView
        // Tuỳ theo strategy, ta gọi các hàm load khác nhau:
        switch loadType {
        case .fastest:
            context.coordinator.fastestLoad(adUnitIDs)
        case .hfFastest:
            context.coordinator.hfFastestLoad(adUnitIDs)
        case .prioritySync:
            context.coordinator.prioritySyncLoad(adUnitIDs)
        case .priorityAsync:
            context.coordinator.priorityAsyncLoad(adUnitIDs)
        }
        
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Không cần cập nhật gì trong ví dụ này
    }
    
    // MARK: - Coordinator
    class Coordinator: NSObject, GADBannerViewDelegate {
        let parent: BannerAdView
        
        var containerView: UIView?
        
        /// Danh sách banner đang load/quản lý
        var bannerViews: [GADBannerView] = []
        
        /// Biến cờ: đã hiển thị banner nào chưa?
        var hasDisplayedBanner: Bool = false
        
        /// Đếm số banner đã hoàn tất (thành công hoặc thất bại) trong strategy cần chờ
        var finishedCount = 0
        
        init(_ parent: BannerAdView) {
            self.parent = parent
        }
        
        // ---------------------------------------------------------
        // Type 1: Load đồng thời TẤT CẢ adUnitIDs
        //   - Banner nào load thành công đầu tiên -> hiển thị, huỷ các banner khác.
        // ---------------------------------------------------------
        func fastestLoad(_ adUnitIDs: [String]) {
            guard !adUnitIDs.isEmpty else { return }
            
            for adUnitID in adUnitIDs {
                let bannerView = createBannerView(adUnitID: adUnitID)
                bannerViews.append(bannerView)
                bannerView.load(GADRequest())
            }
        }
        
        // ---------------------------------------------------------
        // Type 2: Load đồng thời TẤT CẢ adUnitIDs TRỪ CUỐI
        //   - Nếu tất cả banner này FAIL -> load banner CUỐI cùng
        //   - Nếu 1 banner bất kỳ SUCCESS -> hiển thị, huỷ những cái khác + không load cuối
        // ---------------------------------------------------------
        func hfFastestLoad(_ adUnitIDs: [String]) {
            guard !adUnitIDs.isEmpty else { return }
            
            // Nếu chỉ có 1 adUnitID -> nó chính là cuối cùng => logic: loadType2 => có thể load thẳng nó
            if adUnitIDs.count == 1 {
                // Trường hợp đặc biệt, ta có thể load thẳng adUnitID[0]
                // (Tuỳ logic, vì "trừ cuối" thì list kia rỗng => fail => load cuối)
                // Ở đây đơn giản ta load nó luôn:
                let bannerView = createBannerView(adUnitID: adUnitIDs[0])
                bannerViews.append(bannerView)
                bannerView.load(GADRequest())
                return
            }
            
            // Cắt mảng: Tất cả trừ phần tử cuối
            let firstIDs = Array(adUnitIDs.dropLast())
            let lastID = adUnitIDs.last!
            
            // Load đồng thời firstIDs
            for adUnitID in firstIDs {
                let bannerView = createBannerView(adUnitID: adUnitID)
                bannerViews.append(bannerView)
                bannerView.load(GADRequest())
            }
            
            // Kịch bản: Nếu tất cả firstIDs fail => load lastID
            // => Ta cần đếm xem có bao nhiêu firstIDs => n
            //    Mỗi banner fail/success => finishedCount++.
            //    Nếu finishedCount == n mà chưa hiển thị banner => load banner cuối.
        }
        
        // ---------------------------------------------------------
        // Type 3: Load tuần tự từ đầu list
        //   - Banner đầu tiên load thành công -> hiển thị, dừng
        //   - Nếu fail => chuyển sang adUnitID kế tiếp
        //   - Nếu hết list không có banner => không hiển thị
        // ---------------------------------------------------------
        func prioritySyncLoad(_ adUnitIDs: [String]) {
            guard !adUnitIDs.isEmpty else { return }
            
            // Lấy adUnitID đầu tiên, load.
            // Nếu thành công -> dừng.
            // Nếu fail -> load tiếp adUnitID thứ hai, ...
            // Ta cài đặt logic "xếp hàng" này bằng cách
            //  mỗi lần fail, ta gọi function loadBanner(index+1).
            
            loadBannerSequential(adUnitIDs, index: 0)
        }
        
        // Hàm đệ quy: load banner adUnitIDs[index], nếu fail => load adUnitIDs[index+1]
        private func loadBannerSequential(_ adUnitIDs: [String], index: Int) {
            if index >= adUnitIDs.count {
                // Hết danh sách, không hiển thị banner nào
                return
            }
            
            let bannerView = createBannerView(adUnitID: adUnitIDs[index])
            bannerView.tag = index // Lưu tạm chỉ số để biết đây là banner của index nào
            bannerViews.append(bannerView)
            bannerView.load(GADRequest())
        }
        
        // ---------------------------------------------------------
        // Type 4:
        //   - Load đồng thời TẤT CẢ adUnitIDs TRỪ CUỐI.
        //   - Đợi tất cả trả về.
        //       + Nếu có ít nhất 1 banner thành công -> hiển thị banner
        //         có vị trí nhỏ nhất trong list (theo thứ tự adUnitIDs).
        //       + Nếu tất cả fail -> load banner cuối cùng -> hiển thị.
        // ---------------------------------------------------------
        func priorityAsyncLoad(_ adUnitIDs: [String]) {
            guard !adUnitIDs.isEmpty else { return }
            
            if adUnitIDs.count == 1 {
                // Nếu chỉ có 1 ID thì nó vừa là "trừ cuối" vừa là "cuối" => logic tuỳ chỉnh
                // Ở đây ta đơn giản load nó luôn:
                let bannerView = createBannerView(adUnitID: adUnitIDs[0])
                bannerViews.append(bannerView)
                bannerView.load(GADRequest())
                return
            }
            
            let firstIDs = Array(adUnitIDs.dropLast())
            let lastID = adUnitIDs.last!
            
            // Load tất cả firstIDs đồng thời
            for (i, adUnitID) in firstIDs.enumerated() {
                let bannerView = createBannerView(adUnitID: adUnitID)
                bannerView.tag = i // Lưu vị trí để xác định thứ tự
                bannerViews.append(bannerView)
                bannerView.load(GADRequest())
            }
            
            // Chúng ta sẽ chờ finishedCount == firstIDs.count.
            //   - Nếu có banner nào SUCCESS => hiển thị banner
            //     có tag nhỏ nhất (tức index nhỏ nhất).
            //   - Nếu không banner nào success => load lastID.
        }
        
        // ---------------------------------------------------------
        // Tạo bannerView + cấu hình chung
        // ---------------------------------------------------------
        private func createBannerView(adUnitID: String) -> GADBannerView {
            let bannerView = GADBannerView(adSize: GADAdSizeBanner)
            bannerView.adUnitID = adUnitID
            bannerView.delegate = self
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                bannerView.rootViewController = rootVC
            }
            
            return bannerView
        }
        
        // ---------------------------------------------------------
        // Delegate callbacks
        // ---------------------------------------------------------
        func bannerViewDidReceiveAdOther(_ bannerView: GADBannerView) {
            // tuỳ vào strategy, ta xử lý khác nhau
            switch parent.loadType {
            
            case .fastest:
                // Ai thành công đầu tiên thì hiển thị, huỷ các banner khác
                if !hasDisplayedBanner {
                    displayBanner(bannerView)
                    cancelOthers(except: bannerView)
                }
                
            case .hfFastest:
                // Chúng ta đang load đồng thời nhóm firstIDs.
                // Nếu banner này success => hiển thị, huỷ tất cả, kể cả không load ID cuối cùng
                if !hasDisplayedBanner {
                    hasDisplayedBanner = true
                    displayBanner(bannerView)
                    cancelOthers(except: bannerView)
                }
                
            case .prioritySync:
                // Load tuần tự.
                // BannerView success => hiển thị + dừng
                if !hasDisplayedBanner {
                    hasDisplayedBanner = true
                    displayBanner(bannerView)
                    cancelOthers(except: bannerView)
                }
                
            case .priorityAsync:
                // Load đồng thời nhóm firstIDs, nhưng phải chờ tất cả chúng xong
                // => tạm thời ta chỉ đánh dấu success/fail
                bannerView.tag = bannerView.tag // sẵn gán
                bannerView.accessibilityIdentifier = "SUCCESS"
            }
        }
        
        func bannerView(_ bannerView: GADBannerView,
                        didFailToReceiveAdWithError error: Error) {
            // Cũng tuỳ strategy
            switch parent.loadType {
            case .fastest:
                // type1: chỉ cần 1 banner success -> hiển thị. Còn fail thì kệ, trừ khi tất cả fail.
                // Ở đây ta không làm gì đặc biệt, vì logic “nếu tất cả fail” => ko hiển thị, tuỳ bạn.
                break
                
            case .hfFastest:
                // type2: Tăng finishedCount.
                // Nếu tất cả (firstIDs) fail => load banner cuối.
                let firstIDsCount = parent.adUnitIDs.count - 1
                finishedCount += 1
                if finishedCount == firstIDsCount && !hasDisplayedBanner {
                    // Tức là tất cả firstIDs đều fail
                    // => load banner cuối
                    if let lastID = parent.adUnitIDs.last {
                        let bannerView = createBannerView(adUnitID: lastID)
                        bannerViews.append(bannerView)
                        bannerView.load(GADRequest())
                    }
                }
                
            case .prioritySync:
                
                if !hasDisplayedBanner {
                    // Xem bannerView đang là index nào
                    let failIndex = bannerView.tag
                    loadBannerSequential(parent.adUnitIDs, index: failIndex + 1)
                }
                
            case .priorityAsync:
                // Đánh dấu banner này fail => increment finishedCount
                bannerView.accessibilityIdentifier = "FAIL"
            }
        }
        
        // ---------------------------------------------------------
        // type4: Đợi tất cả xong => hiển thị banner success sớm nhất
        // => ta cần 1 callback chung "bannerViewDidFinish"
        //    nhưng SDK AdMob không có. Mình sẽ "hack" bằng cách
        //    mỗi lần success/fail => check finishedCount.
        // ---------------------------------------------------------
        func bannerViewWillPresentScreen(_ bannerView: GADBannerView) {
            // Callback AdMob (không quá quan trọng cho logic load)
        }
        
        // "didReceiveAd" hoặc "didFailToReceiveAd" => => increment finishedCount
        // => ta có thể override 1 chỗ chung. Ở đây, ta gộp logic:
        // ta increment xong => if strategy==.type4 => check finishedCount
        //
        // Để đơn giản, ta gộp increment vào delegate success/fail
        //   => sau đó check:
        
        private func cancelOthers(except chosenBanner: GADBannerView) {
            for bv in bannerViews {
                if bv != chosenBanner {
                    bv.delegate = nil
                    bv.removeFromSuperview()
                }
            }
        }
        
        private func displayBanner(_ bannerView: GADBannerView) {
            guard let container = containerView else { return }
            hasDisplayedBanner = true
            
            container.addSubview(bannerView)
            bannerView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                bannerView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                bannerView.centerYAnchor.constraint(equalTo: container.centerYAnchor)
            ])
        }
        
        // MARK: - Handle finishing logic for type4
        override func responds(to aSelector: Selector!) -> Bool {
            // Tạm thời chặn *tất cả* delegate methods =>
            //  cho phép ta intercept callback. Rồi xử lý chung 1 chỗ:
            return super.responds(to: aSelector)
        }
        
        func bannerViewDidRecordImpression(_ bannerView: GADBannerView) {
            // callback AdMob
        }
        
        // iOS AdMob delegate callback chung =>
        //  ta sẽ override "bannerViewDidReceiveAd" và "didFailToReceiveAd"
        //  Trong 2 hàm đó, ta đã +1 finishedCount (riêng type2, type4,...)
        //  => check type4
        private func checkIfAllFirstIDsFinishedForType4() {
            // Đếm xem trong bannerViews (trừ banner cuối) => finishedCount == bannerViews.count?
            let firstCount = parent.adUnitIDs.count - 1
            if finishedCount == firstCount {
                // Tức là tất cả banner "firstIDs" đã success/fail
                // Xem có banner nào success ko:
                let successBanners = bannerViews.filter { $0.accessibilityIdentifier == "SUCCESS" }
                if !successBanners.isEmpty {
                    // Có success => hiển thị banner theo thứ tự index nhỏ nhất
                    // BannerView nào tag nhỏ nhất => hiển thị
                    let sorted = successBanners.sorted { $0.tag < $1.tag }
                    if let firstBanner = sorted.first {
                        if !hasDisplayedBanner {
                            displayBanner(firstBanner)
                            cancelOthers(except: firstBanner)
                        }
                    }
                } else {
                    // Tất cả fail => load banner cuối
                    if let lastID = parent.adUnitIDs.last {
                        let bannerView = createBannerView(adUnitID: lastID)
                        bannerViews.append(bannerView)
                        bannerView.load(GADRequest())
                    }
                }
            }
        }
        
        // Ta cần gọi `checkIfAllFirstIDsFinishedForType4()` sau mỗi success/fail
        // => Sửa lại 2 hàm delegate:
        
        func bannerViewDidReceiveAd_4(_ bannerView: GADBannerView) {
            finishedCount += 1
            checkIfAllFirstIDsFinishedForType4()
        }
        
        func bannerViewDidFail_4(_ bannerView: GADBannerView) {
            finishedCount += 1
            checkIfAllFirstIDsFinishedForType4()
        }
        
        // Để code gọn hơn, ta “switch” 1 chỗ:
        func bannerViewDidReceiveAd(_ bannerView: GADBannerView, forType4: Bool) {
            if forType4 {
                bannerViewDidReceiveAd_4(bannerView)
            } else {
                bannerViewDidReceiveAd(bannerView)
            }
        }
        
        // Tuy nhiên, AdMob delegate không cho override param
        // => ta làm thẳng trong bannerViewDidReceiveAd, bannerViewFailToReceiveAd,
        //    check parent.strategy:
        
        // Xem code chính ở trên:
        //   - Ở case .type4 trong bannerViewDidReceiveAd: ta chỉ đánh dấu success
        //     => bannerView.accessibilityIdentifier = "SUCCESS"
        //     => Tăng finishedCount => checkIfAllFirstIDsFinishedForType4()
        // Tương tự fail => "FAIL".
        
        // T`ối ưu: Bổ sung logic cẩn thận`
        func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
            switch parent.loadType {
            case .priorityAsync:
                bannerView.accessibilityIdentifier = "SUCCESS"
                finishedCount += 1
                checkIfAllFirstIDsFinishedForType4()
            default:
                // Xử lý cũ
                self.bannerViewDidReceiveAdOther(bannerView)
            }
        }
//        
        func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error, forType4: Bool) {
            if forType4 {
                bannerView.accessibilityIdentifier = "FAIL"
                finishedCount += 1
                checkIfAllFirstIDsFinishedForType4()
            } else {
                self.bannerView(bannerView, didFailToReceiveAdWithError: error)
            }
        }
//        
    }
}
