extension Data {
	public subscript(address: Address) -> Byte {
		get {
			return self[Int(address)]
		}
		set {
			self[Int(address)] = newValue
		}
	}
}
