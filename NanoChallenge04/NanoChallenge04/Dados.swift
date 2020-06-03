//
//  Dados.swift
//  NanoChallenge04
//
//  Created by Gustavo Yamauchi on 03/06/20.
//  Copyright © 2020 Grupo14. All rights reserved.
//

import Foundation



class Dados {
    
    public var Creditos: Int?
    public var Recorde: Int?
    public var Upgrade: Int?
     
    public func carregarDados(){
        let dadosCarregar : [String:String] = UserDefaults.standard.dictionary(forKey: "Dados") as! [String : String]
        
        self.Creditos = Int(dadosCarregar["Creditos"]!)
        self.Recorde  = Int(dadosCarregar["Recorde"]!)
        self.Upgrade  = Int(dadosCarregar["Upgrade"]!)
    }
    
    public func salvarDados(){
        let dadosSalvar : [String:String] = ["Creditos": String(self.Creditos!), "Recorde": String(self.Recorde!), "Upgrade": String(self.Upgrade!)]
        
        UserDefaults.standard.set(dadosSalvar, forKey: "Dados")
    }
    
}
