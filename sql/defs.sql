create table entries (
    rowid integer not null primary key,
    created_at timestamp default current_timestamp not null,
    updated_at timestamp,
    content text not null,
    location text
);

create table entries_tags (
    entry_id integer not null, 
    tag text not null,
    foreign key(entry_id) references entries(rowid),
    primary key(entry_id, tag)
);

create table attributes (
    rowid integer not null primary key,
    name text not null unique,
    type text not null
);

create table entries_attributes (
    entry_id integer not null, 
    attribute_id integer not null,
    value text not null,
    foreign key(entry_id) references entries(rowid),
    foreign key(attribute_id) references attributes(rowid),
    primary key(entry_id, attribute_id)
);