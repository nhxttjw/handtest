create or replace package sys_mail_pkg is

  -- Author  : Razgriz.Tang
  -- Created : 2011-6-1
  -- Purpose : 邮件发送

  /*
    将需要发送的邮件信息插入到邮件待发送列表中
  */
  procedure insert_mailing_list(p_notify_record_id in number,
                                p_mail_to          in varchar2,
                                p_mail_cc          in varchar2,
                                p_subject          in varchar2,
                                p_body             in clob,
                                p_user_id          in number,
                                p_mail_source      in varchar2 default null,
                                p_mail_source_id   in varchar2 default null,
                                p_content_type     in varchar2 default null);

  PROCEDURE update_mail_sent_flag(p_mailing_list_id NUMBER);

  PROCEDURE update_mail_sent_note(p_mailing_list_id NUMBER);

  PROCEDURE update_mail_sent_note(p_mailing_list_id NUMBER,
                                  p_note            VARCHAR2);

  PROCEDURE send_mail(p_mail_to        VARCHAR2,
                      p_mail_cc        VARCHAR2,
                      p_mail_subject   VARCHAR2,
                      p_mail_body      CLOB,
                      p_user_id        NUMBER,
                      p_mail_source    IN VARCHAR2 DEFAULT NULL,
                      p_mail_source_id IN VARCHAR2 DEFAULT NULL,
                      p_content_type   IN VARCHAR2 DEFAULT NULL);

  /*
    从邮件待发送列表中发送邮件
  */
  procedure send_mail;

  procedure send_mail(p_request_id number);
end sys_mail_pkg;
/
create or replace package body sys_mail_pkg is

  type vc2_table is table of varchar2(1) index by binary_integer;
  map vc2_table;

  -- Private Function
  procedure log(p_mailing_list_id number,
                p_log_text        varchar2,
                p_user_id         number) is
    pragma autonomous_transaction;
  begin
    insert into sys_mail_logs
      (log_id,
       mailing_list_id,
       log_text,
       creation_date,
       created_by,
       last_update_date,
       last_updated_by)
    values
      (sys_mail_log_s.nextval,
       p_mailing_list_id,
       p_log_text,
       sysdate,
       p_user_id,
       sysdate,
       p_user_id);
    commit;
  END log;

  -- Initialize the Base64 mapping
  PROCEDURE demo_base64_init_map IS
  BEGIN
    MAP(0) := 'A';
    MAP(1) := 'B';
    MAP(2) := 'C';
    MAP(3) := 'D';
    MAP(4) := 'E';
    MAP(5) := 'F';
    MAP(6) := 'G';
    MAP(7) := 'H';
    MAP(8) := 'I';
    MAP(9) := 'J';
    MAP(10) := 'K';
    MAP(11) := 'L';
    MAP(12) := 'M';
    MAP(13) := 'N';
    MAP(14) := 'O';
    MAP(15) := 'P';
    MAP(16) := 'Q';
    MAP(17) := 'R';
    MAP(18) := 'S';
    MAP(19) := 'T';
    MAP(20) := 'U';
    MAP(21) := 'V';
    MAP(22) := 'W';
    MAP(23) := 'X';
    MAP(24) := 'Y';
    MAP(25) := 'Z';
    MAP(26) := 'a';
    MAP(27) := 'b';
    MAP(28) := 'c';
    MAP(29) := 'd';
    MAP(30) := 'e';
    MAP(31) := 'f';
    MAP(32) := 'g';
    MAP(33) := 'h';
    MAP(34) := 'i';
    MAP(35) := 'j';
    MAP(36) := 'k';
    MAP(37) := 'l';
    MAP(38) := 'm';
    MAP(39) := 'n';
    MAP(40) := 'o';
    MAP(41) := 'p';
    MAP(42) := 'q';
    MAP(43) := 'r';
    MAP(44) := 's';
    MAP(45) := 't';
    MAP(46) := 'u';
    MAP(47) := 'v';
    MAP(48) := 'w';
    MAP(49) := 'x';
    MAP(50) := 'y';
    MAP(51) := 'z';
    MAP(52) := '0';
    MAP(53) := '1';
    MAP(54) := '2';
    MAP(55) := '3';
    MAP(56) := '4';
    MAP(57) := '5';
    MAP(58) := '6';
    MAP(59) := '7';
    MAP(60) := '8';
    MAP(61) := '9';
    MAP(62) := '+';
    MAP(63) := '/';
  END demo_base64_init_map;

  FUNCTION demo_base64_encode(r IN RAW) RETURN VARCHAR2 IS
    i PLS_INTEGER;
    x PLS_INTEGER;
    y PLS_INTEGER;
    v VARCHAR2(32767);
  BEGIN
  
    demo_base64_init_map;
  
    -- For every 3 bytes, split them into 4 6-bit units and map them to
    -- the Base64 characters
    i := 1;
    WHILE (i + 2 <= utl_raw.length(r)) LOOP
      x := to_number(utl_raw.substr(r, i, 1), '0X') * 65536 +
           to_number(utl_raw.substr(r, i + 1, 1), '0X') * 256 +
           to_number(utl_raw.substr(r, i + 2, 1), '0X');
      y := floor(x / 262144);
      v := v || MAP(y);
      x := x - y * 262144;
      y := floor(x / 4096);
      v := v || MAP(y);
      x := x - y * 4096;
      y := floor(x / 64);
      v := v || MAP(y);
      x := x - y * 64;
      v := v || map(x);
      i := i + 3;
    end loop;
  
    -- Process the remaining bytes that has fewer than 3 bytes.
    if (utl_raw.length(r) - i = 0) then
      x := to_number(utl_raw.substr(r, i, 1), '0X');
      y := floor(x / 4);
      v := v || map(y);
      x := x - y * 4;
      x := x * 16;
      v := v || map(x);
      v := v || '==';
    elsif (utl_raw.length(r) - i = 1) then
      x := to_number(utl_raw.substr(r, i, 1), '0X') * 256 +
           to_number(utl_raw.substr(r, i + 1, 1), '0X');
      y := floor(x / 1024);
      v := v || map(y);
      x := x - y * 1024;
      y := floor(x / 16);
      v := v || map(y);
      x := x - y * 16;
      x := x * 4;
      v := v || map(x);
      v := v || '=';
    end if;
  
    return v;
  
  end demo_base64_encode;

  procedure update_mail_sent_flag(p_mailing_list_id number) is
    v_mailing_list_id  number;
    v_notify_record_id number;
    v_mail_to          varchar2(4000);
    v_mail_cc          varchar2(4000);
    v_subject          varchar2(2000);
    v_created_by       number;
    v_creation_date    date;
    v_last_updated_by  number;
    v_last_update_date date;
    v_body             clob;
  begin
    update sys_notify_record r
       set r.status           = 'SENT',
           r.send_time        = sysdate,
           r.last_update_date = sysdate
     where r.record_id =
           (select l.notify_record_id
              from sys_mailing_list l
             where l.mailing_list_id = p_mailing_list_id);
  
    select t.mailing_list_id,
           t.notify_record_id,
           t.mail_to,
           t.mail_cc,
           t.subject,
           t.created_by,
           t.creation_date,
           t.last_updated_by,
           t.last_update_date,
           t.body
      into v_mailing_list_id,
           v_notify_record_id,
           v_mail_to,
           v_mail_cc,
           v_subject,
           v_created_by,
           v_creation_date,
           v_last_updated_by,
           v_last_update_date,
           v_body
      from sys_mailing_list t
     where t.mailing_list_id = p_mailing_list_id;
  
    insert into sys_mailing_list_ht
      (mailing_list_id,
       notify_record_id,
       mail_to,
       mail_cc,
       subject,
       body,
       note,
       sent_flag,
       created_by,
       creation_date,
       last_updated_by,
       last_update_date)
    values
      (v_mailing_list_id,
       v_notify_record_id,
       v_mail_to,
       v_mail_cc,
       v_subject,
       v_body,
       '',
       'Y',
       v_created_by,
       v_creation_date,
       v_last_updated_by,
       v_last_update_date);
  
    delete from sys_mailing_list where mailing_list_id = p_mailing_list_id;
  end update_mail_sent_flag;

  procedure update_mail_sent_note(p_mailing_list_id number,
                                  p_note            varchar2) is
  begin
    update sys_mailing_list
       set note             = p_note,
           error_times      = error_times + 1,
           last_update_date = sysdate
     where mailing_list_id = p_mailing_list_id;
  
    update sys_notify_record r
       set r.status = 'ERROR', r.last_update_date = sysdate
     where r.record_id =
           (select l.notify_record_id
              from sys_mailing_list l
             where l.mailing_list_id = p_mailing_list_id);
  end update_mail_sent_note;

  procedure update_mail_sent_note(p_mailing_list_id number) is
  begin
    update sys_mailing_list
       set note             = '接收邮箱地址为空!',
           error_times      = 11,
           last_update_date = sysdate
     where mailing_list_id = p_mailing_list_id;
  
    update sys_notify_record r
       set r.status = 'ERROR', r.last_update_date = sysdate
     where r.record_id =
           (select l.notify_record_id
              from sys_mailing_list l
             where l.mailing_list_id = p_mailing_list_id);
  end update_mail_sent_note;

  --异步式邮件发送机制，先插入到邮件发送列表中，通过job方式在正式发送邮件
  procedure insert_mailing_list(p_notify_record_id in number,
                                p_mail_to          in varchar2,
                                p_mail_cc          in varchar2,
                                p_subject          in varchar2,
                                p_body             in clob,
                                p_user_id          in number,
                                p_mail_source      in varchar2 default null,
                                p_mail_source_id   in varchar2 default null,
                                p_content_type     in varchar2 default null) is
    v_id number;
  begin
    select sys_mailing_list_s.nextval into v_id from dual;
    insert into sys_mailing_list
      (mailing_list_id,
       notify_record_id,
       mail_to,
       mail_cc,
       subject,
       BODY,
       sent_flag,
       created_by,
       creation_date,
       last_updated_by,
       last_update_date,
       mail_source,
       mail_source_id,
       content_type)
    values
      (v_id,
       p_notify_record_id,
       p_mail_to,
       p_mail_cc,
       p_subject,
       p_body,
       'N',
       p_user_id,
       sysdate,
       p_user_id,
       sysdate,
       p_mail_source,
       p_mail_source_id,
       p_content_type);
  END;

  --Send Mail
  function send_mail(p_smtp_host       varchar2,
                     p_port_number     number,
                     p_auth_login_flag varchar2,
                     p_username        varchar2,
                     p_password        varchar2,
                     p_mail_from       varchar2,
                     p_mail_tolist     varchar2,
                     p_mail_cclist     varchar2,
                     p_subject         varchar2,
                     p_body            clob,
                     p_display_name    varchar2,
                     p_reply_to        varchar2,
                     p_error_code      out varchar2,
                     p_content_type    varchar2 default null) return number is
  
    v_ret        number;
    v_error_code varchar2(100);
    v_conn       utl_smtp.connection;
    --v_crlf       varchar2(2) := chr(13) || chr(10);
    --v_body       varchar2(4000) := null;
  
    v_address_count binary_integer := 0;
  
    v_mail_to     varchar2(200);
    v_mail_tolist varchar2(4000);
    v_begin_idx   number := 1;
    v_end_idx     number := 0;
    v_length      number := 0;
    --v_reply               utl_smtp.reply;
    mesg                  varchar2(32767) := null;
    v_db_nls_characterset varchar2(40); --Oracle数据库的字符集
    v_content_type        varchar2(30);
  begin
    if p_content_type is null then
      v_content_type := 'text/html';
    else
      v_content_type := p_content_type;
    end if;
  
    if p_mail_tolist is null then
      v_ret        := -1;
      v_error_code := 'SYS_MAIL_NO_MAIL_TOLIST_ERROR';
      p_error_code := v_error_code;
      return v_ret;
    end if;
  
    select value
      into v_db_nls_characterset
      from nls_database_parameters
     where parameter = 'NLS_CHARACTERSET';
  
    v_conn := utl_smtp.open_connection(p_smtp_host, nvl(p_port_number, 25));
  
    utl_smtp.helo(v_conn, p_smtp_host);
  
    if nvl(p_auth_login_flag, 'N') = 'Y' then
      utl_smtp.ehlo(v_conn, p_smtp_host); --modify by zhanglei 2010-3-17  只有需要密码验证时，才执行该语句
    
      utl_smtp.command(v_conn, 'AUTH LOGIN');
      utl_smtp.command(v_conn,
                       demo_base64_encode(utl_raw.cast_to_raw(p_username)));
      utl_smtp.command(v_conn,
                       demo_base64_encode(utl_raw.cast_to_raw(p_password)));
    end if;
  
    utl_smtp.mail(v_conn, p_mail_from);
  
    v_mail_tolist := p_mail_tolist;
    loop
      v_end_idx := instr(v_mail_tolist, ',,', 1);
      if v_end_idx = 0 then
        exit;
      end if;
      v_mail_tolist := replace(v_mail_tolist, ',,', ',');
    end loop;
  
    dbms_output.put_line(v_mail_tolist);
  
    ---接收者
    v_length := length(v_mail_tolist);
  
    loop
      v_end_idx := instr(v_mail_tolist, ',', v_begin_idx + 1);
      if v_end_idx = 0 then
        v_end_idx := v_length + 1;
        v_mail_to := substr(v_mail_tolist,
                            v_begin_idx,
                            v_end_idx - v_begin_idx);
      
        if instr(v_mail_to, '@', 1) > 0 then
          utl_smtp.rcpt(v_conn, v_mail_to);
          v_address_count := v_address_count + 1;
        
        end if;
        exit;
      end if;
    
      v_mail_to := substr(v_mail_tolist,
                          v_begin_idx,
                          v_end_idx - v_begin_idx);
      if instr(v_mail_to, '@', 1) > 0 then
        utl_smtp.rcpt(v_conn, v_mail_to);
        v_address_count := v_address_count + 1;
      
      end if;
    
      v_begin_idx := v_end_idx + 1;
    
      if v_begin_idx >= v_length then
        exit;
      end if;
    end loop;
  
    ---抄送
    if p_mail_cclist is not null then
      v_length    := length(p_mail_cclist);
      v_begin_idx := 1;
      v_end_idx   := 0;
      loop
        v_end_idx := instr(p_mail_cclist, ',', v_begin_idx + 1);
        if v_end_idx = 0 then
          v_end_idx := v_length + 1;
          v_mail_to := substr(p_mail_cclist,
                              v_begin_idx,
                              v_end_idx - v_begin_idx);
          if instr(v_mail_to, '@', 1) > 0 then
            utl_smtp.rcpt(v_conn, v_mail_to);
            v_address_count := v_address_count + 1;
          
          end if;
          exit;
        end if;
      
        v_mail_to := substr(p_mail_cclist,
                            v_begin_idx,
                            v_end_idx - v_begin_idx);
        if instr(v_mail_to, '@', 1) > 0 then
          utl_smtp.rcpt(v_conn, v_mail_to);
          v_address_count := v_address_count + 1;
        
        end if;
        v_begin_idx := v_end_idx + 1;
      
        if v_begin_idx >= v_length then
          exit;
        end if;
      end loop;
    end if;
  
    if v_address_count = 0 then
      utl_smtp.quit(v_conn);
      v_ret        := -1;
      v_error_code := 'SYS_MAIL_NO_MAIL_TOLIST_ERROR';
      p_error_code := v_error_code;
      return v_ret;
    end if;
  
    --v_body := v_body || ' ' || v_crlf || p_body;
    mesg := 'MIME-Version: 1.0' || utl_tcp.crlf || 'From: =?UTF-8?b?' ||
            demo_base64_encode(utl_raw.cast_to_raw(p_display_name)) ||
            '?= <' || p_mail_from || '>' || utl_tcp.crlf || 'To: ' ||
            v_mail_tolist || '<' || v_mail_tolist || '>' || utl_tcp.crlf ||
            'Date:' || to_char(SYSDATE,
                               'yyyy-mm-dd hh24:mi:ss',
                               'NLS_DATE_LANGUAGE=AMERICAN') --必须设定nls_date_language，否则由于数据库nls_date_language的不同，会导致转换后的日期格式邮件客户端无法识别，而看不到发送时间。
            || utl_tcp.crlf || 'Subject: =?UTF-8?b?' ||
            demo_base64_encode(utl_raw.cast_to_raw(p_subject)) || '?=' --convert(p_subject,'ZHS16GBK',v_db_NLS_CHARACTERSET)-- 这里是标题
           --convert('中文数据',src =>应与Oracle客户端使用的NLS_LANG字符集一致,destcset => 应与Oracle数据库的字符集一致)否则标题乱码
           
            || utl_tcp.crlf || 'Content-Type: ' || v_content_type ||
            '; charset=UTF-8' -- 这个字符集要与Oracle客户端OS字符集一致
            || utl_tcp.crlf || 'Content-Transfer-Encoding: base64' ||
            utl_tcp.crlf || utl_tcp.crlf ||
            demo_base64_encode(utl_raw.cast_to_raw(p_body));
  
    utl_smtp.open_data(v_conn);
  
    /*utl_smtp.write_raw_data(v_conn,
                            utl_raw.cast_to_raw(convert('From:' ||
                                                        p_mail_from ||
                                                        utl_tcp.CRLF,
                                                        'ZHS16CGB231280')));
    
    utl_smtp.write_raw_data(v_conn,
                            utl_raw.cast_to_raw(convert('To:' ||
                                                        p_mail_tolist ||
                                                        utl_tcp.CRLF,
                                                        'ZHS16CGB231280')));
    
    if p_mail_cclist is not null then
      utl_smtp.write_raw_data(v_conn,
                              utl_raw.cast_to_raw(convert('cc:' ||
                                                          p_mail_cclist ||
                                                          utl_tcp.CRLF,
                                                          'ZHS16CGB231280')));
    end if;
    
    utl_smtp.write_raw_data(v_conn,
                            utl_raw.cast_to_raw(convert('Subject:' ||
                                                        p_subject ||
                                                        utl_tcp.CRLF,
                                                        'ZHS16CGB231280')));
    utl_smtp.write_raw_data(v_conn,
                            utl_raw.cast_to_raw(convert(utl_tcp.CRLF ||
                                                        v_body,
                                                        'ZHS16CGB231280')));*/
  
    utl_smtp.write_raw_data(v_conn,
                            utl_raw.cast_to_raw(convert(mesg,
                                                        'ZHS16CGB231280',
                                                        v_db_nls_characterset)));
    utl_smtp.close_data(v_conn);
    utl_smtp.quit(v_conn);
  
    v_ret        := 0;
    v_error_code := null;
    p_error_code := v_error_code;
    return v_ret;
  
  exception
    when utl_smtp.transient_error then
      utl_smtp.quit(v_conn);
      v_ret        := -1;
      v_error_code := 'SYS_MAIL_SEND_MAIL_ERROR';
      p_error_code := v_error_code;
      sys_raise_app_error_pkg.raise_sys_others_error(p_message                 => dbms_utility.format_error_backtrace ||
                                                                                  sqlerrm,
                                                     p_created_by              => 1,
                                                     p_package_name            => 'SYS_NOTIFY_PKG',
                                                     p_procedure_function_name => 'UPDATE_NOTIFY_RECIPIENT');
      raise_application_error(sys_raise_app_error_pkg.c_error_number,
                              sys_raise_app_error_pkg.g_err_line_id);
      return v_ret;
    when utl_smtp.permanent_error then
      utl_smtp.quit(v_conn);
      v_ret        := -1;
      v_error_code := 'SYS_MAIL_SEND_MAIL_ERROR';
      p_error_code := v_error_code;
      sys_raise_app_error_pkg.raise_sys_others_error(p_message                 => dbms_utility.format_error_backtrace ||
                                                                                  sqlerrm,
                                                     p_created_by              => 1,
                                                     p_package_name            => 'SYS_NOTIFY_PKG',
                                                     p_procedure_function_name => 'UPDATE_NOTIFY_RECIPIENT');
      raise_application_error(sys_raise_app_error_pkg.c_error_number,
                              sys_raise_app_error_pkg.g_err_line_id);
      return v_ret;
    when others then
      utl_smtp.quit(v_conn);
      v_ret        := -1;
      v_error_code := 'SYS_MAIL_SEND_MAIL_ERROR';
      p_error_code := v_error_code;
      sys_raise_app_error_pkg.raise_sys_others_error(p_message                 => dbms_utility.format_error_backtrace ||
                                                                                  sqlerrm,
                                                     p_created_by              => 1,
                                                     p_package_name            => 'SYS_NOTIFY_PKG',
                                                     p_procedure_function_name => 'UPDATE_NOTIFY_RECIPIENT');
      raise_application_error(sys_raise_app_error_pkg.c_error_number,
                              sys_raise_app_error_pkg.g_err_line_id);
      return v_ret;
  end send_mail;

  procedure send_mail(p_mail_to        varchar2,
                      p_mail_cc        varchar2,
                      p_mail_subject   varchar2,
                      p_mail_body      clob,
                      p_user_id        number,
                      p_mail_source    in varchar2 default null,
                      p_mail_source_id in varchar2 default null,
                      p_content_type   in varchar2 default null) is
  
    v_mail_server_id sys_mail_server.mail_server_id%type;
  begin
  
    --if v_mail_server_id is null then
    begin
      select mail_server_id
        into v_mail_server_id
        from sys_mail_server
       where default_flag = 'Y';
    exception
      when others then
        v_mail_server_id := -1;
    end;
    --end if;
  
    insert_mailing_list(p_notify_record_id => nvl(p_mail_source_id,
                                                  v_mail_server_id),
                        p_mail_to          => p_mail_to,
                        p_mail_cc          => p_mail_cc,
                        p_subject          => p_mail_subject,
                        p_body             => p_mail_body,
                        p_user_id          => p_user_id,
                        p_mail_source      => p_mail_source,
                        p_mail_source_id   => p_mail_source_id,
                        p_content_type     => p_content_type);
  end;

  --从邮件发送列表中发送邮件
  procedure send_mail is
    v_lock       number;
    v_ret        number;
    v_error_code varchar2(100);
  
    r_sys_mail_list sys_mailing_list%rowtype;
  
    r_sys_mail_server sys_mail_server%rowtype;
  
    e_mail_server_notfound exception;
    e_locked_error exception;
    pragma exception_init(e_locked_error, -54);
  
    cursor c_mailing_list is
      select *
        from sys_mailing_list
       where sent_flag = 'N'
         and error_times <= 10;
  
  BEGIN
    BEGIN
      SELECT *
        INTO r_sys_mail_server
        FROM sys_mail_server s
       WHERE s.enabled_flag = 'Y'
         AND rownum = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE e_mail_server_notfound;
    END;
  
    OPEN c_mailing_list;
    LOOP
      FETCH c_mailing_list
        INTO r_sys_mail_list;
      EXIT WHEN c_mailing_list%NOTFOUND;
    
      v_error_code := NULL;
    
      --锁表
      begin
        select 1
          into v_lock
          from sys_mailing_list t
         where t.mailing_list_id = r_sys_mail_list.mailing_list_id
           and t.sent_flag = 'N'
           and error_times <= 10
           for update nowait;
      
        if trim(r_sys_mail_list.mail_to) is null then
          update_mail_sent_note(r_sys_mail_list.mailing_list_id);
        else
          v_ret := send_mail(p_smtp_host       => r_sys_mail_server.mail_smtp_host,
                             p_port_number     => r_sys_mail_server.mail_port_number,
                             p_auth_login_flag => r_sys_mail_server.auth_login_flag,
                             p_username        => r_sys_mail_server.mail_username,
                             p_password        => r_sys_mail_server.mail_password,
                             p_mail_from       => r_sys_mail_server.mail_address,
                             p_mail_tolist     => r_sys_mail_list.mail_to,
                             p_mail_cclist     => r_sys_mail_list.mail_cc,
                             p_subject         => r_sys_mail_list.subject,
                             p_body            => r_sys_mail_list.body,
                             p_display_name    => r_sys_mail_server.display_name,
                             p_reply_to        => r_sys_mail_server.reply_to,
                             p_error_code      => v_error_code,
                             p_content_type    => r_sys_mail_list.content_type);
          if v_ret = 0 then
            update_mail_sent_flag(r_sys_mail_list.mailing_list_id);
          else
            update_mail_sent_note(r_sys_mail_list.mailing_list_id,
                                  v_error_code);
          end if;
        end if;
      
        commit;
      
      exception
        when no_data_found then
          rollback;
        when e_locked_error then
          log(p_mailing_list_id => r_sys_mail_list.mailing_list_id,
              p_log_text        => 'sys_mailing_list locked',
              p_user_id         => -1);
          ROLLBACK;
        WHEN OTHERS THEN
          log(p_mailing_list_id => r_sys_mail_list.mailing_list_id,
              p_log_text        => dbms_utility.format_error_backtrace ||
                                   SQLERRM,
              p_user_id         => -1);
          ROLLBACK;
      END;
    END LOOP;
    CLOSE c_mailing_list;
  
  exception
    when e_mail_server_notfound then
      log(p_mailing_list_id => null,
          p_log_text        => 'sys_alert_rules_mail_config no_data_found',
          p_user_id         => -1);
      ROLLBACK;
      /*when others then
      if c_mailing_list%isopen then
        close c_mailing_list;
      end if;
      log(p_mailing_list_id => r_sys_mail_list.mailing_list_id,
          p_log_text        => dbms_utility.format_error_backtrace ||
                               sqlerrm,
          p_user_id         => -1);
      rollback;*/
  END;

  PROCEDURE send_mail(p_request_id NUMBER) IS
  BEGIN
    --sys_notify_template_pkg.send_notify; 消息分发单独配置请求 modify 2016-6-29 @tony
    send_mail;
  end send_mail;
end sys_mail_pkg;
/
