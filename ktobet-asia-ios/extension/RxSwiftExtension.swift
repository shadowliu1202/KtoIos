import RxSwift
import SharedBu

extension Single where PrimitiveSequence.Trait == RxSwift.SingleTrait {
    public func catchException() -> PrimitiveSequence<Trait, Element> {
        let handler : (Swift.Error) throws -> PrimitiveSequence<Trait, Element> = { (error) in
            return Single.error(ExceptionFactory.toKtoException(error))
        }
        return catchError(handler)
    }
}

extension ObservableType {
    public func catchException() -> Observable<Element> {
        let handler : (Swift.Error) throws -> Observable<Element> = { (error) in
            return Observable.error(ExceptionFactory.toKtoException(error))
        }
        return catchError(handler)
    }
}

extension Completable {
    func catchException() -> PrimitiveSequence<Trait, Element> {
        let handler : (Swift.Error) throws -> PrimitiveSequence<Trait, Element> = { (error) in
            return Completable.error(ExceptionFactory.toKtoException(error))
        }
        return catchError(handler)
    }
}
