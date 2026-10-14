local Status = {}

function Status.ok(detail)
	return { state = "ok", detail = detail or "" }
end

function Status.fail(detail)
	return { state = "error", detail = detail or "" }
end

function Status.pending(detail)
	return { state = "pending", detail = detail or "Checking..." }
end

return Status