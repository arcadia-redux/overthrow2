var WEB_API_TESTING = Game.IsInToolsMode() && false;
var serverHost = WEB_API_TESTING ? 'http://127.0.0.1:5000' : 'http://163.172.174.77:8000';

function SendWebApiRequest(path, data, onSuccess, onError) {
    var settings = {type: 'POST', data: data};
    if (onSuccess != null) settings.success = onSuccess;
    if (onError != null) settings.error = onError;
    $.AsyncWebRequest(serverHost + '/api/vscripts/' + path, settings);
}

function SubscribeToNetTableKey(tableName, key, callback) {
    var immediateValue = CustomNetTables.GetTableValue(tableName, key) || {};
    callback(immediateValue || {});
    CustomNetTables.SubscribeNetTableListener(tableName, function (_tableName, currentKey, value) {
        if (currentKey === key) callback(value || {});
    });
}

function GetDotaHud() {
    var p = $.GetContextPanel();
    while (p !== null && p.id !== 'Hud') {
        p = p.GetParent();
    }
    if (p === null) {
        throw new HudNotFoundException('Could not find Hud root as parent of panel with id: ' + $.GetContextPanel().id);
    } else {
        return p;
    }
}

function FindDotaHudElement(id) {
    return GetDotaHud().FindChildTraverse(id);
}

function FillTopBarPlayer(TeamContainer) {
    // Fill players top bar in case on partial lobbies
    var playerCount = TeamContainer.GetChildCount();
    for (var i = playerCount + 1; i <= 12; i++) {
        var newPlayer = $.CreatePanel('DOTATopBarPlayer', TeamContainer, 'RadiantPlayer-1');
        if (newPlayer) {
            newPlayer.FindChildTraverse('PlayerColor').style.backgroundColor = '#FFFFFFFF';
        }
        newPlayer.SetHasClass('EnemyTeam', true);
    }
}


function SubscribeToNetTableKey(tableName, tableKey, callback) {
    var listener = CustomNetTables.SubscribeNetTableListener(tableName, function (unusedTableName, receivedKey, receivedData) {
        if (tableKey == receivedKey) {
            if (!receivedData) {
                return;
            }
            callback(receivedData);
        }
    });

    var immediate_data = CustomNetTables.GetTableValue(tableName, tableKey);
    if (immediate_data) {
        callback(immediate_data);
    }

    return listener;
}

function Opt(value) {
    this._value = value;
}

var Optional = {
    empty: function empty() {
        return new Opt();
    },
    of: function of(value) {
        if (value === undefined || value === null) {
            throw new Error('value is not defined');
        }
        return new Opt(value);
    },
    ofNullable: function ofNullable(value) {
        return new Opt(value);
    }
};

Opt.prototype = {
    get: function get() {
        if (isNull(this._value)) {
            throw new Error('optional is empty');
        }
        return this._value;
    },
    isPresent: function isPresent() {
        return !isNull(this._value);
    },
    ifPresent: function ifPresent(consumer) {
        if (!isNull(this._value)) {
            if (!isFunction(consumer)) {
                throw new Error('consumer is not a function');
            }
            consumer(this._value);
        }
    },
    filter: function filter(predicate) {
        if (!isFunction(predicate)) {
            throw new Error('predicate is not a function');
        }
        if (!isNull(this._value) && predicate(this._value)) {
            return new Opt(this._value);
        }
        return new Opt();
    },
    map: function map(mapper) {
        var mappedValue;

        if (!isFunction(mapper)) {
            throw new Error('mapper is not a function');
        }

        if (isNull(this._value)) {
            return new Opt();
        }

        mappedValue = mapper(this._value);

        return isNull(mappedValue) ? new Opt() : new Opt(mappedValue);
    },
    flatMap: function flatMap(mapper) {
        var flatMappedValue;

        if (!isFunction(mapper)) {
            throw new Error('mapper is not a function');
        }

        if (isNull(this._value)) {
            return new Opt();
        }

        flatMappedValue = mapper(this._value);

        if (isNull(flatMappedValue) || isNull(flatMappedValue.get)) {
            throw new Error('mapper does not return an Optional');
        }

        return flatMappedValue;
    },
    peek: function peek(peeker) {
        if (!isFunction(peeker)) {
            throw new Error('peeker is not a function');
        }

        if (isNull(this._value)) {
            return new Opt();
        }

        peeker(this._value);

        return new Opt(this._value);
    },
    orElse: function orElse(other) {
        return isNull(this._value) ? other : this._value;
    },
    orElseGet: function orElseGet(supplier) {
        if (!isFunction(supplier)) {
            throw new Error('supplier is not a function');
        }
        if (isNull(this._value)) {
            return supplier();
        } else {
            return this._value;
        }
    },
    orElseThrow: function orElseThrow(exceptionSupplier) {
        if (isNull(this._value)) {
            if (!isFunction(exceptionSupplier)) {
                throw new Error('exception provider is not a function');
            }

            throw exceptionSupplier();
        }
        return this._value;
    },
    ifPresentOrElse: function ifPresentOrElse(consumer, elseCallable) {
        if (!isNull(this._value)) {
            this.ifPresent(consumer);
        } else {
            elseCallable();
        }
    },
    or: function or(optionalSupplier) {
        if (isNull(this._value)) {
            return optionalSupplier();
        }
        return this;
    }
};

function isNull(value) {
    return (value === undefined || value === null);
}

function isFunction(value) {
    return typeof value === 'function';
}
