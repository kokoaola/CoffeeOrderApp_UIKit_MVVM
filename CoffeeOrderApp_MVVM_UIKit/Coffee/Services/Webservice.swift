//
//  Webservice.swift
//  Coffee
//
//  Created by koala panda on 2023/11/16.
//

import Foundation



///ネットワーク関連のエラーを定義する列挙型
enum NetworkError: Error {
    //データのデコードに関連するエラー（形式が違ったり）
    case decodingError
    //一般的なネットワークリクエストのエラー、（リクエストがサーバーに到達しない、サーバーからのレスポンスがない、サーバーエラーが発生したなど）
    case domainError
    //これはURLに関連するエラー(無効なURL、存在しないエンドポイントへのリクエスト、URLの構成が間違っているなど)
    case urlError
}


///どのHTTPメソッドを使用するかを指定するための列挙型
enum HttpMethod: String {
    case get = "GET"
    case post = "POST"
}


///取得するリソースを表すジェネリック構造体、Codableに準拠する任意の型Tで使用可能
struct Resource<T: Codable> {
    let url: URL
    var httpMethod: HttpMethod = .get
    var body: Data? = nil 
}

///リソースを拡張して、URLの初期値が入力できるようにする
extension Resource {
    init(url: URL) {
        self.url = url
    }
}


///Webサービスを行うクラス
class Webservice {
    
    ///ジェネリック型のリソースをロードし、結果のResult型を非同期で返す関数
    func load<T>(resource: Resource<T>, completion: @escaping (Result<T, NetworkError>) -> Void) {
        
        //resourceをもとにリクエストを作成
        var request = URLRequest(url: resource.url)
        request.httpMethod = resource.httpMethod.rawValue
        request.httpBody = resource.body
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        
        //URLSessionを使用して、リソースのURLからデータを非同期に取得
        URLSession.shared.dataTask(with: request) { data, response, error in
            
            //データがnilでなく、エラーもないことを確認、そうでなければエラーを返す
            guard let data = data, error == nil else {
                completion(.failure(.domainError))
                return
            }
            
            //取得したデータをジェネリック型Tにデコードし、結果を得る
            //もしResource<String>が使われていれば、T.selfはString.selfになり、String型にデコードする
            let result = try? JSONDecoder().decode(T.self, from: data)
            if let result = result {
                //結果がnilでなければメインスレッドで成功結果を返す
                DispatchQueue.main.async {
                    completion(.success(result))
                }
            } else {
                //デコードに失敗した場合はエラーを返す
                completion(.failure(.decodingError))
            }
            
        }.resume() //データタスクを開始する.urlSessionとセットで忘れないように
        
    }
    
}
