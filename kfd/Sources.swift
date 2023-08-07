import SwiftUI
import Foundation
import Combine

struct Repository: Codable, Identifiable {
    let id = UUID()
    let repo_name: String
    let repo_desc: String
    let repo_homepage: String
    let repo_update_url: String
    let repo_image: String
    let objects: Objects
}

struct Objects: Codable {
    let packages: [Package]
}

class Package: Codable, Identifiable {
    let id = UUID()
    let package_name: String
    let package_url: String
    let package_type: String
    var installed: Bool

    // Add an init method to allow decoding with default values
    init(package_name: String, package_url: String, package_type: String, installed: Bool = false) {
        self.package_name = package_name
        self.package_url = package_url
        self.package_type = package_type
        self.installed = installed
    }

    // Add custom coding keys if necessary
    enum CodingKeys: String, CodingKey {
        case package_name
        case package_url
        case package_type
        case installed
    }

    // Provide a default value for the `installed` property
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.package_name = try container.decode(String.self, forKey: .package_name)
        self.package_url = try container.decode(String.self, forKey: .package_url)
        self.package_type = try container.decode(String.self, forKey: .package_type)
        self.installed = try container.decodeIfPresent(Bool.self, forKey: .installed) ?? false
    }
}
class SourcesViewModel: ObservableObject {
    @Published var repositories: [Repository] = []

    private var cancellables = Set<AnyCancellable>()

    init() {
        loadRepositories()
    }

    func loadRepositories() {
        if let reposFileURL = Bundle.main.url(forResource: "repos", withExtension: "json") {
            do {
                let data = try Data(contentsOf: reposFileURL)
                let decoder = JSONDecoder()
                self.repositories = try decoder.decode([Repository].self, from: data)

                // Load images for repositories
                loadRepositoryImages()
            } catch {
                print("Error loading repos.json: \(error)")
            }
        } else {
            print("repos.json file not found in the app bundle.")
        }
    }

    func loadRepositoryImages() {
        repositories.forEach { repository in
            guard let imageUrl = URL(string: repository.repo_image) else { return }
            URLSession.shared.dataTaskPublisher(for: imageUrl)
                .tryMap { data, response in
                    guard let image = UIImage(data: data) else {
                        throw URLError(.badServerResponse)
                    }
                    return image
                }
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        break // Do nothing on completion
                    case .failure(let error):
                        print("Error loading image: \(error)")
                    }
                }, receiveValue: { image in
                    repositoryImageCache[repository.id] = image
                    self.objectWillChange.send()
                })
                .store(in: &cancellables)
        }
    
}
    func installPackage(_ package: Package) {
        guard let packageURL = URL(string: package.package_url) else { return }
        URLSession.shared.dataTaskPublisher(for: packageURL)
            .map { $0.data }
            .receive(on: DispatchQueue.global())
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break // Do nothing on completion
                case .failure(let error):
                    print("Error loading package data: \(error)")
                }
            }, receiveValue: { data in
                let fileManager = FileManager.default
                let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
                let packageURL = documentsURL.appendingPathComponent("\(package.package_name).\(URL(fileURLWithPath: package.package_url).pathExtension)")
                do {
                    try data.write(to: packageURL)
                    package.installed = true
                    self.saveInstalledPackages()
                    self.objectWillChange.send()
                } catch {
                    print("Error saving package: \(error)")
                }
            })
            .store(in: &cancellables)
    }

    func deletePackage(_ package: Package) {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let packageURL = documentsURL.appendingPathComponent("\(package.package_name).\(URL(fileURLWithPath: package.package_url).pathExtension)")
        do {
            try fileManager.removeItem(at: packageURL)
            package.installed = false
            self.saveInstalledPackages()
            self.objectWillChange.send()
        } catch {
            print("Error deleting package: \(error)")
        }
    }

    // Add this method to save the installed packages to packages.json
    func saveInstalledPackages() {
        let installedPackages = repositories.flatMap { $0.objects.packages.filter { $0.installed } }
        let packageURLs = installedPackages.map { $0.package_url }
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let packagesURL = documentsURL.appendingPathComponent("packages.json")
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(packageURLs)
            try data.write(to: packagesURL)
        } catch {
            print("Error saving installed packages: \(error)")
        }
    }
}

// Cache to store loaded images
var repositoryImageCache = [UUID: UIImage]()

struct SourcesView: View {
    @StateObject var viewModel = SourcesViewModel()
    var body: some View {
        TabView {
            NavigationView {
                List(viewModel.repositories) { repository in
                    NavigationLink(destination: PackagesView(packages: repository.objects.packages)) {
                        HStack {
                            if let image = repositoryImageCache[repository.id] {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 50, height: 50)
                            } else {
                                ProgressView()
                                    .frame(width: 50, height: 50)
                            }
                            VStack(alignment: .leading) {
                                Text(repository.repo_name)
                                    .font(.headline)
                                Text(repository.repo_desc)
                                    .font(.subheadline)
                            }
                        }
                    }
                }
                .navigationTitle("Sources")
            }
          //  .navigationViewStyle(StackNavigationViewStyle())
         //   .tabItem {
           //     Image(systemName: "list.bullet")
          //      Text("Sources")
            }
          //  .tag(0)

            // Add other tabs as needed
        }
}

struct PackagesView: View {
    
    @EnvironmentObject var viewModel: SourcesViewModel
    var packages: [Package]
    
    var body: some View {
        List(packages) { package in
            VStack(alignment: .leading) {
                Text(package.package_name)
                    .font(.headline)
                Text(package.package_type)
                    .font(.subheadline)
                // You can add more details about the package here

                Button(action: {
                    if package.installed {
                        viewModel.deletePackage(package)
                    } else {
                        viewModel.installPackage(package)
                    }
                }) {
                    Text(package.installed ? "Uninstall" : "Install")
                }
            }
        }
        .navigationTitle("Packages")
    }
}
