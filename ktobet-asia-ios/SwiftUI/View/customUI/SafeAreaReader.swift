import SwiftUI

class SafeAreaMonitor: ObservableObject {
    @Published var safeAreaSize: CGSize = .init(width: 1, height: 1)
    @Published var safeAreaInsets: EdgeInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0 )
}

struct SafeAreaReader<Content: View>: View {
    
    @StateObject private var safeAreaMonitor = SafeAreaMonitor()
    
    let ignoresRegions: SafeAreaRegions?
    
    var content: Content
    
    init(ignoresSafeArea ignoresRegions: SafeAreaRegions? = nil, @ViewBuilder content: () -> Content) {
        self.ignoresRegions = ignoresRegions
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            IgnoreSafeAreaCover(ignoresRegions) {
                Color.clear
                    .overlay(
                        GeometryReader { geometryProxy in
                            Rectangle()
                                .foregroundColor(.clear)
                                .onAppear {
                                    safeAreaMonitor.safeAreaSize = geometryProxy.size
                                    
                                    safeAreaMonitor.safeAreaInsets = geometryProxy.safeAreaInsets
                                }
                                .onChange(of: geometryProxy.size) { size in
                                    safeAreaMonitor.safeAreaSize = size
                                }
                                .onChange(of: geometryProxy.safeAreaInsets) { insets in
                                    safeAreaMonitor.safeAreaInsets = insets
                                }
                        }
                    )
            }
            
            content
                .environmentObject(safeAreaMonitor)
        }
    }
}

extension SafeAreaReader {
    
    struct IgnoreSafeAreaCover<Content: View>: View {
        
        let ignoresRegions: SafeAreaRegions?
        
        var content: Content
        
        init(_ ignoresRegions: SafeAreaRegions?, @ViewBuilder content: () -> Content) {
            self.ignoresRegions = ignoresRegions
            self.content = content()
        }
        
        var body: some View {
            if let regions = ignoresRegions {
                content
                    .ignoresSafeArea(regions)
            }
            else {
                content
            }
        }
    }
}

struct SafeAreaReader_Previews: PreviewProvider {
    
    struct Preview: View {
        @EnvironmentObject private var safeAreaMonitor: SafeAreaMonitor
        
        @State private var isViewInTopSide: Bool = false
        
        var body: some View {
            ScrollView {
                Rectangle()
                    .foregroundColor(.gray)
                    .frame(width: 300, height: 200)
                
                Rectangle()
                    .foregroundColor(.pink)
                    .frame(width: 300, height: 100)
                    .overlay(
                        TextField("Tap here to show keyboard.", text: .constant(""))
                    )
                    .overlay(
                        GeometryReader { geometry in
                            
                            Text("midY: " + geometry.frame(in: .global).midY.description)
                                .background(Color.yellow)
                                .frame(
                                    maxWidth: .infinity,
                                    maxHeight: .infinity,
                                    alignment: .top
                                )
                            
                            Text("View In Top Side: " + isViewInTopSide.description)
                                .background(isViewInTopSide ? Color.yellow : Color.purple)
                                .frame(
                                    maxWidth: .infinity,
                                    maxHeight: .infinity,
                                    alignment: .bottom
                                )
                        }
                    )
                    .positionDetect(result: $isViewInTopSide)
                
                Rectangle()
                    .foregroundColor(.gray)
                    .frame(width: 300, height: 300)
            }
        }
    }
    
    static var previews: some View {
        SafeAreaReader {
            Preview()
        }
        
        SafeAreaReader(ignoresSafeArea: .keyboard) {
            Preview()
        }
    }
}
