import SwiftUI

final class LoadingPlaceholderViewModel: ObservableObject {
  @Published var isLoading = true
  @Published var type: LoadingPlaceholder.`Type`

  init(_ type: LoadingPlaceholder.`Type`) {
    self.type = type
  }
}

struct LoadingPlaceholder: View {
  enum `Type`: Int {
    case casino
    case casinoLobby
    case slot
    case slotAllGame
    case slotSeeMore
    case arcade
    case numberGame
    case p2p
    case favorite

    var shouldAddMask: Bool {
      self == .favorite ||
        self == .casinoLobby ||
        self == .slotSeeMore
    }
  }

  @StateObject var viewModel: LoadingPlaceholderViewModel

  var type: `Type` { viewModel.type }
  var isLoading: Bool { viewModel.isLoading }
  var backgroundOpacity: Double { isLoading ? 1 : 0 }

  var onViewDisappear: () -> Void = { }

  var breathType: Breath.`Type` = .breath

  var body: some View {
    ZStack {
      Color.from(.black131313, alpha: 0.8)
        .ignoresSafeArea()
        .opacity(backgroundOpacity)
        .onAnimationCompleted(for: backgroundOpacity) {
          onViewDisappear()
        }
        .animation(
          isLoading ? nil : .linear(duration: 0.3),
          value: backgroundOpacity)

      ScrollView(showsIndicators: false) {
        switch type {
        case .casinoLobby,
             .favorite,
             .slotSeeMore:
          buildFavorite()

        case .arcade,
             .casino:
          buildCasino()

        case .numberGame,
             .slot:
          buildSlot()

        case .slotAllGame:
          buildSlotAllGame()

        case .p2p:
          buildP2P()
        }
      }
      .padding(.horizontal, 22)
      .if(type.shouldAddMask) {
        masking($0)
      }
      .pageBackgroundColor(.black131313)
      .visibility(isLoading ? .visible : .invisible)
    }
  }

  func buildCasino() -> some View {
    Group {
      LimitSpacer(180)
      tags
      LimitSpacer(70)
      list(3)
    }
  }

  func buildSlot() -> some View {
    Group {
      LimitSpacer(150)

      breathView
        .frame(width: 200, height: 200)
        .cornerRadius(10)

      LimitSpacer(60)

      VStack(alignment: .leading, spacing: 30) {
        ForEach(0..<2, id: \.self) { _ in
          breathView
            .frame(width: 120, height: 32)
          row
        }
      }
    }
  }

  func buildP2P() -> some View {
    Group {
      LimitSpacer(80)

      VStack(alignment: .leading, spacing: 30) {
        breathView
          .frame(width: 120, height: 40)

        ForEach(0..<2, id: \.self) { _ in
          VStack(alignment: .leading, spacing: 9) {
            breathView
              .frame(idealHeight: 172)
              .cornerRadius(10)
            breathView
              .frame(width: 100, height: 20)
          }
        }
      }
    }
  }

  func buildFavorite() -> some View {
    Group {
      LimitSpacer(80)
      list(3)
    }
  }

  func buildSlotAllGame() -> some View {
    Group {
      LimitSpacer(52)

      VStack(alignment: .leading, spacing: 46) {
        breathView
          .frame(width: 120, height: 40)
        list(4)
      }
    }
  }
}

// MARK: - Component

extension LoadingPlaceholder {
  func masking(_ view: some View) -> some View {
    view.mask(
      Rectangle()
        .fill(
          .linearGradient(
            .init(colors: [
              Color.from(.black131313, alpha: 0),
              Color.from(.black131313, alpha: 0.4),
              Color.from(.black131313, alpha: 1)
            ]),
            startPoint: .bottom,
            endPoint: .top)))
  }

  func list(_ count: Int) -> some View {
    VStack(spacing: 30) {
      ForEach(0..<count, id: \.self) { _ in
        row
      }
    }
  }

  var tags: some View {
    HStack(spacing: 8) {
      ForEach(0..<4, id: \.self) { _ in
        breathView
          .frame(width: 64, height: 32)
          .cornerRadius(16)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  var row: some View {
    HStack(spacing: 15) {
      ForEach(0..<3, id: \.self) { _ in
        item
      }
    }
  }

  var item: some View {
    VStack(spacing: 8) {
      breathView
        .aspectRatio(1, contentMode: .fit)
        .cornerRadius(10)
      breathView
        .frame(height: 20)
    }
  }

  var breathView: some View {
    Breath(type: breathType)
  }
}

extension LoadingPlaceholder {
  struct Breath: View {
    enum `Type` {
      case breath
      case direction(start: UnitPoint, end: UnitPoint)
    }

    @State private var isBreathing = false

    var type: `Type` = .breath

    var body: some View {
      Group {
        switch type {
        case .breath:
          buildBreath()
        case .direction(let start, let end):
          buildDirection(start: start, end: end)
        }
      }
      .onAppear {
        isBreathing.toggle()
      }
    }

    func buildBreath() -> some View {
      ZStack {
        Color.from(.black2B2B2B)
        Color.from(.gray202020)
          .opacity(isBreathing ? 0 : 1)
          .animation(
            .linear(duration: 1)
              .repeatForever(autoreverses: true),
            value: isBreathing)
      }
    }

    func buildDirection(start: UnitPoint, end: UnitPoint) -> some View {
      Color.from(.gray202020)
        .overlay(
          ZStack {
            Color.from(.black2B2B2B)
              .mask(
                Rectangle()
                  .fill(
                    LinearGradient(
                      gradient: .init(colors: [
                        .white,
                        .clear
                      ]),
                      startPoint: start,
                      endPoint: isBreathing ? end : start)))
          }
          .animation(
            .easeOut(duration: 1.5)
              .repeatForever(autoreverses: false),
            value: isBreathing))
    }
  }
}

// MARK: - Preview

struct LoadingPlaceholder_Previews: PreviewProvider {
  static var previews: some View {
    LoadingPlaceholder(viewModel: .init(.casino))
    LoadingPlaceholder(viewModel: .init(.slot))
    LoadingPlaceholder(viewModel: .init(.p2p))
    LoadingPlaceholder(viewModel: .init(.favorite))
    LoadingPlaceholder(viewModel: .init(.slotAllGame))
  }
}
