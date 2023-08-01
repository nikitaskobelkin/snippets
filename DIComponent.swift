//  The SpaceXComponent is a NeedleFoundation component that provides the SpaceXViewModel and builds the SwiftUI view for the SpaceX feature.
//  It conforms to the ViewBuildProtocol, and its buildView() method constructs the SpaceXView SwiftUI view with the appropriate
//  dependencies. The component requires the DataManagerProtocol dependency.

import NeedleFoundation
import SwiftUI

protocol SpaceXDependency: Dependency {
    var dataManager: DataManagerProtocol { get }
}

final class SpaceXComponent: Component<SpaceXDependency>, ViewBuildProtocol {
    var viewModel: SpaceXViewModel {
        SpaceXViewModel(dataManager: dependency.dataManager)
    }

    @ViewBuilder func buildView() -> some View {
        SpaceXView(
            viewModel,
            launchComponent: LaunchComponent(parent: self)
        )
    }
}
