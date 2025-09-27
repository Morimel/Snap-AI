//
//  AppImages.swift
//  SnapAI
//
//  Created by Isa Melsov on 16/9/25.
//

import SwiftUI

enum AppImages {
    enum Activity {
        static let sedantary = Image("sedantary")
        static let normal = Image("normal")
        static let active = Image("active")
    }

    enum Gender {
        static let male = Image("male")
        static let female = Image("female")
        static let other = Image("other")
    }

    enum Goal {
        static let maleGoal = Image("maleGoal")
        static let femaleGoal = Image("femaleGoal")
        static let otherGoal = Image("otherGoal")
    }
    
    enum Avatars {
        static let avatar1 = Image("avatar1")
        static let avatar2 = Image("avatar2")
        static let avatar3 = Image("avatar3")
    }
    
    enum ButtonIcons {
        static let gear = Image("gear")
        static let camera1 = Image("camera2")
        static let gallery = Image("gallery")
        static let keyboard = Image("keyboard")
        static let share = Image("share")
        static let arrowLeft = Image("arrowLeft")
        static let arrowRight = Image("arrowRight")
        static let cross = Image("cross")
        static let minus = Image("minus")
        
        enum Star {
            static let activeStar = Image("activeStar")
            static let inactiveStar = Image("inactiveStar")
        }
        
        enum Pen {
            static let lightPen = Image("lightPen")
            static let darkPen = Image("darkPen")
        }
        
        enum Plus {
            static let lightPlus = Image("lightPlus")
            static let darkPlus = Image("darkPlus")
        }
    }
    
    enum Other {
        static let plateApple = Image("plateApple")
        static let apple = Image("apple")
        static let calculator = Image("calculator")
        static let list1 = Image("list1")
        static let list2 = Image("list2")
        static let weight = Image("weight")
        static let toolsPlate = Image("toolsPlate")
        static let statistic = Image("statistic")
        static let mark = Image("mark")
        static let camera2 = Image("camera2")
    }

    enum OtherImages {
        static let food1 = Image("food1")
        static let food2 = Image("food2")
        static let avocado = Image("avocado")
        static let splashBack = Image("splashBack")
        static let weightCards = Image("weightCards")
    }
}
