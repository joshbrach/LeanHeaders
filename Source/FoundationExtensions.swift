//
//  FoundationExtensions.swift
//  LeanHeaders
//
//  Created by Joshua Brach on 03/03/2018.
//  Copyright © 2018 Joshua Brach.  Distributed under the GNU GPLv3.
//

import Foundation


extension Sequence {
    /// Returns a dictionary of arrays, keyed by the results of mapping the
    /// given closure over the sequence's elements.
    ///
    /// Partitions the sequence into equivalence classes defined by the key
    /// function.
    ///
    /// - Parameter key: A mapping closure. Accepts an element of this
    ///   sequence as its parameter and returns the key to which the element
    ///   should be associated.
    /// - Returns: A dictionary associating keys resulting from the given
    ///   closure to arrays of all the elements of this sequence which resulted
    ///   in that key.
    public func keyed<K: Hashable>(by key: (Self.Element) throws -> K) rethrows -> [K : [Self.Element]] {
        return try self.reduce(into: [:]) { (soFar, next) in
            let k = try key(next)
            if soFar[k] == nil {
                soFar[k] = [next]
            } else {
                soFar[k]!.append(next)
            }
        }
    }
}
