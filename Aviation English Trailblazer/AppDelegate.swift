//
//  AppDelegate.swift
//  Aviation English Trailblazer
//
//  Created by Steven Siu  on 28/10/2021.
//

import UIKit

// How to sign app
// https://zhuanlan.zhihu.com/p/359449443

// Loaded nib but the 'view' outlet was not set
// https://stackoverflow.com/questions/4763519/loaded-nib-but-the-view-outlet-was-not-set

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var appCoordinator: AppCoordinator!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        setupCoordinator()

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
}

private extension AppDelegate {
    // MARK: PROPERTIES
    var navigationController: UINavigationController {
        let navigationController = UINavigationController()
        navigationController.isNavigationBarHidden = true

        return navigationController
    }

    // MARK: COORDINATOR
    func setupCoordinator() {
        window = UIWindow()
        guard let window = window else { return }

        let navigator = Navigator(navigationController: navigationController)
        appCoordinator = AppCoordinator(window: window, navigator: navigator)
        appCoordinator.start()
        window.makeKeyAndVisible()
    }
}
