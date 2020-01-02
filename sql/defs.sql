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
