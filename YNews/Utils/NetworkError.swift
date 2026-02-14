//
//  NetworkError.swift
//  YNews
//
//  Created by Gaurav Bhardwaj on 14/02/26.
//

import Foundation


enum NetworkError: Error, Equatable {

    case noInternet

    case serverError(message: String)

    case requestFailed(message: String)


    static func from(_ error: Error) -> NetworkError {
        if let ne = error as? NetworkError { return ne }

        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet,
                 .networkConnectionLost,
                 .cannotConnectToHost,
                 .cannotFindHost,
                 .dataNotAllowed:
                return .noInternet
            case .timedOut:
                return .requestFailed(message: "The request timed out. Please try again.")
            default:
                return .requestFailed(message: urlError.localizedDescription)
            }
        }

        if error is DecodingError {
            return .serverError(message: "The server returned unexpected data. Please try again later.")
        }

        return .serverError(message: error.localizedDescription)
    }


    var title: String {
        switch self {
        case .noInternet:           return "No Internet Connection"
        case .serverError:          return "Something Went Wrong"
        case .requestFailed:        return "Request Failed"
        }
    }

    var message: String {
        switch self {
        case .noInternet:
            return "You're not connected to the internet.\nPlease check your network settings and try again."
        case .serverError(let msg):
            return msg
        case .requestFailed(let msg):
            return msg
        }
    }

    var icon: String {
        switch self {
        case .noInternet:    return "wifi.slash"     
        case .serverError:   return "exclamationmark.triangle"
        case .requestFailed: return "clock.badge.xmark"
        }
    }
}
